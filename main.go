package main

import (
	"fmt"
	"os"
)

// Main entrypoint of the application
func main() {
	// Ensure we at least have one argument
	if len(os.Args) <= 1 {
		showHelp()
		os.Exit(1)
	}

	// Extract the fileName from the first argument
	fileName := os.Args[1]
	if fileName != "" {
		fmt.Println(fileName)
	}
}

// Shows the help message
func showHelp() {
	fmt.Println("Scratchpad")
}
