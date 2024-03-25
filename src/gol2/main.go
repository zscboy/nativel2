package main

/*
#include <stdlib.h>
*/
import "C"
import "unsafe"

import (
	"fmt"
	"encoding/json"
	"time"
	"sync"
)


const (
	VERSION string = "1.0.0"
)

var (
	isRunning bool
	counter int
	lock sync.Mutex
	serviceNotify chan bool
	serviceDone chan bool
)

func counterService(notify <- chan  bool, end chan <- bool) {
	ticker := time.NewTicker(3000 * time.Millisecond)
	for {
		select {
		case <-notify:
			goto EXIT
		case <-ticker.C:
			counter++
		}
	}

EXIT:
	end <- true
}

//export StartDaemon
func StartDaemon(jsonStrPtr *C.char) *C.char {
	var err error
	var resultJson []byte

	result := struct {
		Code int `json:code`
		Msg string `json:msg`
	}{
		Code: -1,
		Msg: "unknown error",
	}

	// marshal to json object
	args := struct {
		LogPath string `json:logPath`
		ConfigPath string `json:configPath`
	}{};

	jsonStr := C.GoString(jsonStrPtr)
	err = json.Unmarshal([]byte(jsonStr), &args)
	if err != nil {
		result.Msg = fmt.Sprintf("marshal input args failed:%v", err)

		goto EXIT;
	}

	// dump to console
	fmt.Printf("start daemon with:%+v\n", args)

	// start go-routine
	lock.Lock()
	defer lock.Unlock()

	if isRunning {
		result.Msg = "daemon is running"
		goto EXIT;
	}

	serviceNotify = make(chan bool, 1)
	serviceDone = make(chan bool, 1)
	go counterService(serviceNotify, serviceDone)

	isRunning = true

	result.Code = 0
	result.Msg = "ok"

EXIT:
	resultJson, _ = json.Marshal(result)
	return C.CString(string(resultJson))
}

//export StopDaemon
func StopDaemon() *C.char {
	var resultJson []byte

	result := struct {
		Code int `json:code`
		Msg string `json:msg`
	}{
		Code: -1,
		Msg: "unknown error",
	}

	lock.Lock()
	defer lock.Unlock()

	if !isRunning {
		result.Msg = "daemon is not running"
		goto EXIT;
	}

	serviceNotify <- true
	select {
	case <-serviceDone:
	}

	isRunning = false

	result.Code = 0
	result.Msg = "ok"
EXIT:

	resultJson, _ = json.Marshal(result)
	return C.CString(string(resultJson))
}

//export DaemonState
func DaemonState() *C.char {
	var resultJson []byte

	result := struct {
		Code int `json:code`
		IsRunning bool `json:running`
		Counter int `json:counter`
	}{
		Code: 0,
		IsRunning: isRunning,
		Counter: counter,
	}

	resultJson, _ = json.Marshal(result)
	return C.CString(string(resultJson))
}

//export DaemonVersion
func DaemonVersion() *C.char {
	var resultJson []byte

	result := struct {
		Code int `json:code`
		Version string `json:version`
	}{
		Code: 0,
		Version: VERSION,
	}

	resultJson, _ = json.Marshal(result)
	return C.CString(string(resultJson))
}

//export Sign
func Sign(jsonStrPtr *C.char) *C.char {
	var resultJson []byte
	var err error

	result := struct {
		Code int `json:code`
		Msg string `json:msg`
		Hash string `json:hash`
	}{
		Code: -1,
		Msg: "unknown error",
	}

	// marshal to json object
	args := struct {
		Message string `json:message`
	}{};
	
	jsonStr := C.GoString(jsonStrPtr)
	err = json.Unmarshal([]byte(jsonStr), &args)
	if err != nil {
		result.Msg = fmt.Sprintf("marshal input args failed:%v", err)

		goto EXIT;
	}

	if len(args.Message) == 0 {
		result.Msg = "input message is empty"

		goto EXIT;
	}

	// dump to console
	fmt.Printf("sign with:%+v\n", args)

	result.Code = 0
	result.Msg = "ok"
	result.Hash = args.Message // copy back

EXIT:
	resultJson, _ = json.Marshal(result)
	return C.CString(string(resultJson))
}

func main() {
	args := struct {
		LogPath string `json:logPath`
		ConfigPath string `json:configPath`
	}{
		LogPath: "/var/lib/gol2.log",
		ConfigPath: "/var/lib/gol2.toml",
	};

	resultJson, _ := json.Marshal(args)
	resultJsonPtr := C.CString(string(resultJson))
	ret := StartDaemon(resultJsonPtr)
	retStr := C.GoString(ret)
	C.free(unsafe.Pointer(ret))
	C.free(unsafe.Pointer(resultJsonPtr))

	fmt.Printf("startDaemon result:%s\n", retStr)

	time.Sleep(15*time.Second)

	ret = StopDaemon()
	retStr = C.GoString(ret)
	C.free(unsafe.Pointer(ret))

	fmt.Printf("stopDaemon result:%s, counter:%d\n", retStr, counter)
}
