/**
 * TypeScript type definitions for PTC Tools
 * 
 * This file provides type definitions for all available tools.
 * Import these types to get autocomplete and type checking.
 */

// ===== FS Tools =====

export interface FsReadInput {
  path: string;
  encoding?: "utf8" | "base64";
}

export interface FsReadOutput {
  content: string;
  size: number;
  exists: boolean;
  modified?: number;
}

export interface FsWriteInput {
  path: string;
  content: string;
  encoding?: "utf8" | "base64";
  append?: boolean;
}

export interface FsWriteOutput {
  success: boolean;
  path: string;
  size: number;
  error?: string;
}

export interface FsGlobInput {
  pattern: string;
  root?: string;
  dot?: boolean;
  maxDepth?: number;
}

export interface FsGlobOutput {
  files: string[];
  count: number;
  root: string;
}

export interface FsMkdirInput {
  path: string;
  recursive?: boolean;
}

export interface FsMkdirOutput {
  success: boolean;
  path: string;
  existed: boolean;
  error?: string;
}

export interface FsDeleteInput {
  path: string;
  recursive?: boolean;
}

export interface FsDeleteOutput {
  success: boolean;
  path: string;
  existed: boolean;
  error?: string;
}

// ===== Git Tools =====

export interface GitStatusInput {
  path?: string;
}

export interface GitStatusOutput {
  isRepo: boolean;
  branch: string;
  isClean: boolean;
  modified: string[];
  untracked: string[];
  staged: string[];
  deleted: string[];
  renamed: { old: string; new: string }[];
  ahead?: number;
  behind?: number;
  error?: string;
}

export interface GitDiffInput {
  path?: string;
  from?: string;
  to?: string;
  file?: string;
}

export interface GitDiffOutput {
  success: boolean;
  diff: string;
  hasChanges: boolean;
  filesChanged: number;
  error?: string;
}

export interface GitCommitInput {
  path?: string;
  message: string;
  all?: boolean;
  files?: string[];
}

export interface GitCommitOutput {
  success: boolean;
  hash?: string;
  error?: string;
}

export interface GitLogCommit {
  hash: string;
  shortHash: string;
  author: string;
  email: string;
  date: string;
  message: string;
  files?: string[];
}

export interface GitLogInput {
  path?: string;
  limit?: number;
  file?: string;
  stat?: boolean;
  format?: "oneline" | "short" | "full";
}

export interface GitLogOutput {
  success: boolean;
  commits: GitLogCommit[];
  total?: number;
  error?: string;
}

export interface GitBranchInfo {
  name: string;
  current: boolean;
  remote?: string;
  ahead?: number;
  behind?: number;
}

export interface GitBranchInput {
  path?: string;
  list?: boolean;
  create?: string;
  from?: string;
  switch?: string;
  delete?: string;
  force?: boolean;
}

export interface GitBranchOutput {
  success: boolean;
  current?: string;
  branches?: GitBranchInfo[];
  error?: string;
}

// ===== HTTP Tools =====

export interface HttpFetchInput {
  url: string;
  headers?: Record<string, string>;
  followRedirects?: boolean;
  timeout?: number;
}

export interface HttpFetchOutput {
  success: boolean;
  status: number;
  headers: Record<string, string>;
  body: string;
  size: number;
  error?: string;
}

export interface HttpPostInput {
  url: string;
  body?: unknown;
  contentType?: string;
  headers?: Record<string, string>;
  timeout?: number;
}

export interface HttpPostOutput {
  success: boolean;
  status: number;
  headers: Record<string, string>;
  body: string;
  json?: unknown;
  error?: string;
}

export interface HttpDownloadInput {
  url: string;
  destination: string;
  headers?: Record<string, string>;
  timeout?: number;
}

export interface HttpDownloadOutput {
  success: boolean;
  path: string;
  size: number;
  contentType?: string;
  error?: string;
}

// ===== Search Tools =====

export interface SearchGrepMatch {
  file: string;
  line: number;
  content: string;
  column?: number;
}

export interface SearchGrepInput {
  pattern: string;
  path?: string;
  recursive?: boolean;
  ignoreCase?: boolean;
  regex?: boolean;
  maxResults?: number;
  include?: string;
  exclude?: string;
}

export interface SearchGrepOutput {
  success: boolean;
  matches: SearchGrepMatch[];
  count: number;
  error?: string;
}

export interface SearchFindFileInfo {
  path: string;
  name: string;
  size: number;
  isDirectory: boolean;
  modified: number;
}

export interface SearchFindInput {
  path?: string;
  name?: string;
  pattern?: string;
  type?: "f" | "d";
  maxDepth?: number;
  minSize?: number;
  maxSize?: number;
  modifiedAfter?: number;
  modifiedBefore?: number;
}

export interface SearchFindOutput {
  success: boolean;
  files: SearchFindFileInfo[];
  count: number;
  error?: string;
}

// ===== Shell Tools =====

export interface ShellExecInput {
  command: string;
  args?: string[];
  cwd?: string;
  env?: Record<string, string>;
  timeout?: number;
  maxOutput?: number;
}

export interface ShellExecOutput {
  success: boolean;
  code: number;
  stdout: string;
  stderr: string;
  output: string;
  executionTime: number;
  error?: string;
}

// ===== Tool Registry =====

export interface Tools {
  fs: {
    read(input: FsReadInput): Promise<FsReadOutput>;
    write(input: FsWriteInput): Promise<FsWriteOutput>;
    glob(input: FsGlobInput): Promise<FsGlobOutput>;
    mkdir(input: FsMkdirInput): Promise<FsMkdirOutput>;
    delete(input: FsDeleteInput): Promise<FsDeleteOutput>;
  };
  git: {
    status(input?: GitStatusInput): Promise<GitStatusOutput>;
    diff(input?: GitDiffInput): Promise<GitDiffOutput>;
    commit(input: GitCommitInput): Promise<GitCommitOutput>;
    log(input?: GitLogInput): Promise<GitLogOutput>;
    branch(input?: GitBranchInput): Promise<GitBranchOutput>;
  };
  http: {
    fetch(input: HttpFetchInput): Promise<HttpFetchOutput>;
    post(input: HttpPostInput): Promise<HttpPostOutput>;
    download(input: HttpDownloadInput): Promise<HttpDownloadOutput>;
  };
  search: {
    grep(input: SearchGrepInput): Promise<SearchGrepOutput>;
    find(input?: SearchFindInput): Promise<SearchFindOutput>;
  };
  shell: {
    exec(input: ShellExecInput): Promise<ShellExecOutput>;
  };
}

// ===== Progress Function =====

export type ProgressFn = (step: string, data?: Record<string, unknown>) => void;
