package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/DataDog/datadog-go/v5/statsd"
	httptrace "gopkg.in/DataDog/dd-trace-go.v1/contrib/net/http"
	"gopkg.in/DataDog/dd-trace-go.v1/ddtrace/tracer"
	"gopkg.in/DataDog/dd-trace-go.v1/profiler"
)

func main() {
	err := profiler.Start(
		profiler.WithProfileTypes(
			profiler.CPUProfile,
			profiler.HeapProfile,
			profiler.BlockProfile,
			profiler.MutexProfile,
			profiler.GoroutineProfile,
		),
	)
	if err != nil {
		log.Fatal(err)
	}
	defer profiler.Stop()

	tracer.Start()
	defer tracer.Stop()

	statsd, err := statsd.New("127.0.0.1:8125")

	if err != nil {
		log.Fatal(err)
	}
	mux := httptrace.NewServeMux()

	fmt.Println("listening...")
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("hello world!"))
		fmt.Println("hello world!")
		statsd.Incr("pcf.testing.custom_metrics.incr", []string{"go:foo", "pcf"}, 1)
		statsd.Decr("pcf.testing.custom_metrics.decr", []string{"foo:go", "pcf"}, 1)
	})
	http.ListenAndServe(":8080", mux)
}
