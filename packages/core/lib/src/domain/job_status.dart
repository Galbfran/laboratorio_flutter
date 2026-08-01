enum JobStatus {
  pending,
  uploading,
  done,
  failed,
  permanentlyFailed;

  bool get isTerminal => this == done || this == permanentlyFailed;
}
