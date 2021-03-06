package main

import (
  "fmt"
  "net/http"
 )

func main() {
  fmt.Println("Starting application ...")
  http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
    fmt.Fprintf(w, "Hello, you've requested: %s\n", r.URL.Path)
  })

  fmt.Println("Starting HTTP server on port 8080")
  http.ListenAndServe(":8080", nil)
}
