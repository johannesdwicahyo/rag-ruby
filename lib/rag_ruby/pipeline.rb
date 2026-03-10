# frozen_string_literal: true

require "securerandom"

module RagRuby
  class Pipeline
    attr_reader :config

    def initialize(&block)
      @config = Configuration.new
      yield @config if block_given?
      @prompt_template = PromptTemplate.new
      @chunk_store = {} # id -> chunk mapping
    end

    def ingest(source, loader: nil)
      loader ||= @config.loader_instance || Loaders::File.new

      # Load documents
      fire(:before_load, source)
      documents = loader.load(source)
      fire(:after_load, documents)

      documents.each do |doc|
        next if doc.empty?

        # Chunk
        fire(:before_chunk, doc)
        chunks = chunk_document(doc)
        fire(:after_chunk, chunks)

        # Embed
        fire(:before_embed, chunks)
        embed_chunks(chunks)
        fire(:after_embed, chunks)

        # Store
        fire(:before_store, chunks)
        store_chunks(chunks)
        fire(:after_store, chunks)
      end
    end

    def ingest_directory(dir_path, glob: "**/*.{md,txt}")
      loader = Loaders::Directory.new(glob: glob)
      ingest(dir_path, loader: loader)
    end

    def query(question, top_k: 5, filter: nil, temperature: 0.7, system_prompt: nil)
      start_time = Time.now

      fire(:before_query, question)

      # Embed the question
      query_embedding = @config.embedder_instance.embed(question)

      # Search the store
      results = @config.store_instance.search(query_embedding, top_k: top_k, filter: filter)

      # Build sources from results
      sources = results.map do |result|
        chunk = result[:chunk] || @chunk_store[result[:id]]
        next unless chunk

        Source.new(chunk: chunk, score: result[:score])
      end.compact

      # Build context from retrieved chunks
      context = build_context(sources)

      # Generate answer
      prompt_text = @prompt_template.render(context: context, question: question)
      sys_prompt = system_prompt || @prompt_template.system_prompt

      gen_result = @config.generator_instance.generate(
        prompt: prompt_text,
        system_prompt: sys_prompt,
        temperature: temperature
      )

      duration = Time.now - start_time

      answer = Answer.new(
        text: gen_result[:text],
        sources: sources,
        tokens_used: gen_result[:tokens_used],
        duration: duration,
        query: question
      )

      fire(:after_query, question, answer)

      answer
    end

    private

    def chunk_document(doc)
      begin
        require "chunker_ruby"
        chunker = ChunkerRuby::RecursiveCharacter.new(
          chunk_size: @config.chunk_size,
          chunk_overlap: @config.chunk_overlap
        )
        texts = chunker.split(doc.content)
      rescue LoadError
        # Fallback: simple chunking without chunker-ruby
        texts = simple_chunk(doc.content, @config.chunk_size, @config.chunk_overlap)
      end

      texts.each_with_index.map do |text, i|
        chunk_text = text.respond_to?(:text) ? text.text : text.to_s
        Chunk.new(
          text: chunk_text,
          metadata: doc.metadata.dup,
          document_source: doc.source,
          index: i
        )
      end
    end

    def simple_chunk(text, size, overlap)
      chunks = []
      start = 0
      while start < text.length
        chunk_end = [start + size, text.length].min
        chunks << text[start...chunk_end]
        start += size - overlap
        break if start >= text.length
      end
      chunks
    end

    def embed_chunks(chunks)
      texts = chunks.map(&:text)
      embeddings = @config.embedder_instance.embed_batch(texts)
      if embeddings.length != chunks.length
        raise RagRuby::Error, "Embedding count (#{embeddings.length}) doesn't match chunk count (#{chunks.length})"
      end
      chunks.each_with_index do |chunk, i|
        chunk.embedding = embeddings[i]
      end
    end

    def store_chunks(chunks)
      chunks.each do |chunk|
        id = SecureRandom.uuid
        @chunk_store[id] = chunk
        @config.store_instance.add(id, embedding: chunk.embedding, metadata: chunk.metadata, chunk: chunk)
      end
    end

    def build_context(sources, max_chars: 12000)
      context = ""
      sources.each do |source|
        separator = context.empty? ? "" : "\n---\n"
        candidate = context + separator + source.text
        break if candidate.length > max_chars && !context.empty?
        context = candidate
      end
      context.strip
    end

    def fire(event, *args)
      @config.callbacks_for(event).each { |cb| cb.call(*args) }
    end
  end
end
