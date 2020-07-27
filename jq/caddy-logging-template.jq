{
  "@id": $name,
  "encoder": {
    "field": "common_log",
    "format": "single_field"
  },
  "include": [
    $log
  ],
  "writer": {
    "filename": $filename,
    "output": "file"
  }
}
