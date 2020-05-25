package main

import "io/ioutil"
import "fmt"
import "bytes"
import "github.com/aws/aws-sdk-go/aws"
import "github.com/aws/aws-sdk-go/aws/session"
import "github.com/aws/aws-sdk-go/service/s3"
import "github.com/aws/aws-sdk-go/service/kms"
import "github.com/aws/aws-sdk-go/service/s3/s3crypto"

// Set these before running!
const (
	Bucket = ""
	MasterKeyId = ""
	Profile = "default"
	Region = "us-east-1"
)

func get(sess *session.Session, key string) {
	svc := s3crypto.NewDecryptionClient(sess)
	result, err := svc.GetObject(&s3.GetObjectInput {
		Bucket: aws.String(Bucket),
		Key: aws.String(key),
	})
	if (err != nil) {
		fmt.Println(err)
	} else {
		fmt.Println(result)
		b, _ := ioutil.ReadAll(result.Body)
		fmt.Printf("%s\n", b)
	}
}

func put(sess *session.Session, key string, value string) {
	handler := s3crypto.NewKMSKeyGenerator(kms.New(sess), MasterKeyId)
	svc := s3crypto.NewEncryptionClient(sess, s3crypto.AESGCMContentCipherBuilder(handler))
	_, err := svc.PutObject(&s3.PutObjectInput {
		Bucket: aws.String(Bucket),
		Key: aws.String(key),
		Body: bytes.NewReader([]byte(value)),
	})
	if (err != nil) {
		fmt.Println(err)
	}
}

func main () {
	sess := session.Must(session.NewSessionWithOptions(session.Options{
		Config: aws.Config{Region: aws.String(Region)},
		Profile: Profile,
	}))

	put(sess, "go.txt", "hello from go!")
	get(sess, "elixir.txt")
}
