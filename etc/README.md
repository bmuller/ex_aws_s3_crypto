# Go Interoperability
The go file in this folder was used to confirm interoperability with the [AWS SDK for the Go programming language](https://github.com/aws/aws-sdk-go).  Go is used to put a file named "go.txt" and attempts to read a file named "elixir.txt".

## Running
First, edit the top of test.go and set the variables.  Then, make sure go is installed, and run:

```shell
$> go get github.com/jmespath/go-jmespath
$> go get github.com/aws/aws-sdk-go/aws
$> go run test.go
```
