# rag-ruby — Milestones

> **Source of truth:** https://github.com/johannesdwicahyo/rag-ruby/milestones
> **Last synced:** 2026-04-14

This file mirrors the GitHub milestones for this repo. Edit the milestone or issues on GitHub and re-sync, do not hand-edit.

## v1.0.0 — Production Ready (**open**)

_Guardrails integration (guardrails-ruby), evaluation hooks (eval-ruby), full documentation, stable API, production hardening with retry logic, comprehensive error handling, and performance benchmarks._

_No issues._ (0 open, 0 closed reported)

## v0.4.0 — Advanced Features (**open**)

_Reranking (reranker-ruby), hybrid search (vector + BM25), query expansion, conversation memory (multi-turn RAG), caching (embedding cache, answer cache), streaming answers._

_No issues._ (0 open, 0 closed reported)

## v0.3.0 — Rails Integration (**open**)

_RagRuby::Indexable concern for ActiveRecord, Rails generator (rails g rag:install), config via config/rag.yml, background job integration (ActiveJob) for async indexing, RagRuby.search() and RagRuby.ask() global API, controller helpers._

_No issues._ (0 open, 0 closed reported)

## v0.2.0 — More Providers (**closed**)

_PDF loader (pdf-reader), HTML loader (nokogiri), URL loader (fetch + extract), Directory loader (bulk ingest), ONNX embedder (onnx-ruby), Cohere embedder, Memory store for testing, customizable prompt templates._

- [x] #1 Add Cohere embedding provider
- [x] #2 Add Voyage AI embedding provider
- [x] #3 Add Anthropic Claude generator
- [x] #4 Add Google Gemini generator
- [x] #5 Add Ollama local generator
- [x] #6 Add Ollama local embedder
- [x] #7 Add HuggingFace Inference API embedder
- [x] #8 Add chunker-ruby integration for document splitting
- [x] #9 Add reranker-ruby integration for result reranking
- [x] #10 Configurable retrieval strategies (similarity, MMR)
- [x] #11 Test coverage for all providers with WebMock stubs
- [x] #12 Provider auto-detection from API key format

## v0.1.0 — Core Pipeline (**closed**)

_Configurable RAG pipeline with document loading, chunking, embedding, storage, retrieval, and generation. File loader (txt, md), OpenAI embedder, Memory & Zvec stores, OpenAI/ruby_llm generators, pipeline.ingest() and pipeline.query() with callbacks._

_No issues._ (0 open, 0 closed reported)
