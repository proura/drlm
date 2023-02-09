// www/drlm-send-error/drlm-send-error.go

package main

import (
	"bytes"
	"encoding/json"
	"encoding/xml"
	"net/http"
	"os"
)

type ErrorXML struct {
	XMLName       xml.Name `xml:"drlm"`
	Version       string   `xml:"version"`
	Type          string   `xml:"type"`
	Server        string   `xml:"server"`
	Client        string   `xml:"client"`
	Configuration string   `xml:"configuration"`
	OS            string   `xml:"os"`
	Rear          string   `xml:"rear"`
	Workflow      string   `xml:"workflow"`
	Message       string   `xml:"message"`
}

type ErrorJSON struct {
	Program       string `json:"program"`
	Version       string `json:"version"`
	Type          string `json:"type"`
	Server        string `json:"server"`
	Client        string `json:"client"`
	Configuration string `json:"configuration"`
	OS            string `json:"os"`
	Rear          string `json:"rear"`
	Workflow      string `json:"workflow"`
	Message       string `json:"message"`
}

func main() {
	// Load DRLM SEND ERROR configuration vars
	loadDRLMSendErrorConfiguration()

	if configDRLMSendError.DRLMSendErrorURL != "" {

		var body []byte

		if os.Args[1] == "xml" {
			if len(os.Args) == 3 {
				body = []byte(os.Args[2])
			} else {
				error := &ErrorXML{}
				error.Version = os.Args[2]
				error.Type = os.Args[3]
				error.Server = os.Args[4]
				error.Client = os.Args[5]
				error.Configuration = os.Args[6]
				error.OS = os.Args[7]
				error.Rear = os.Args[8]
				error.Workflow = os.Args[9]
				error.Message = os.Args[10]
				body, _ = xml.Marshal(error)
			}
		} else {
			if len(os.Args) == 3 {
				body = []byte(os.Args[2])
			} else {
				error := &ErrorJSON{}
				error.Program = "drlm"
				error.Version = os.Args[2]
				error.Type = os.Args[3]
				error.Server = os.Args[4]
				error.Client = os.Args[5]
				error.Configuration = os.Args[6]
				error.OS = os.Args[7]
				error.Rear = os.Args[8]
				error.Workflow = os.Args[9]
				error.Message = os.Args[10]
				body, _ = json.Marshal(error)
			}
		}

		//If only one argument is provided means that is an XML string
		//else we recieve 9 parameters and have to be Marshalled

		client := &http.Client{}

		//Log the sended error in /var/log/drlm/drlm-send-error-log
		logger.Println("Sending " + os.Args[1] + " error " + string(body) + " to " + configDRLMSendError.DRLMSendErrorURL)

		req, err := http.NewRequest("POST", configDRLMSendError.DRLMSendErrorURL, bytes.NewBuffer([]byte(body)))
		if err != nil {
			logger.Println(err)
		}
		if os.Args[1] == "xml" {
			req.Header.Add("Content-Type", "application/xml; charset=utf-8")
		} else {
			req.Header.Add("Content-Type", "application/json; charset=utf-8")
		}

		//Send request to configDRLMSendError.DRLMSendErrorURL
		resp, err := client.Do(req)
		if err != nil {
			logger.Println(err)
		}
		//Log the response
		logger.Println(resp)
	} else {
		logger.Println("DRLMSendErrorURL not configured. Can not send error.")
	}
}
