package main

import (
	"fmt"
	"os"
	"path/filepath"
)

// Main entrypoint of the application
func main() {

	// Name of the scratchpad file
	scratchpadName := "scratchpad"

	// Scratchpad Directory
	scratchpadDir, err := getScratchpadDir()
	if err != nil {
		fmt.Fprintf(os.Stderr, "ERROR: %e", err)
		os.Exit(1)
	}

	// Ensure that the directory exists
	if _, err := os.Stat(scratchpadDir); os.IsNotExist(err) {
		os.Mkdir(scratchpadDir, os.ModePerm)
	}

	// Extract the first argument
	first := ""
	if len(os.Args) >= 1 {
		first = os.Args[1]
	}

	// Show help if help was requested
	if first == "help" || first == "--help" || first == "-h" {
		showHelp()
		os.Exit(0)
	}

	// Show the version number if requested
	if first == "version" || first == "--version" || first == "-v" {
		showVersion()
		os.Exit(0)
	}

	// At this point, the first argument refers to the scratchpad name
	scratchpadName = first

	fmt.Println(scratchpadName, scratchpadDir)
}

// Shows the help message
func showHelp() {
	fmt.Println("Scratchpad")
}

// Shows the version number
func showVersion() {
	fmt.Println("v0.1.0")
}

// Path to the scratchpad directory
func getScratchpadDir() (string, error) {
	// Get Home Directory
	homedir, err := os.UserHomeDir()
	if err != nil {
		return "", err
	}

	// Scratchpad Directory
	scratchpadDir := filepath.Join(homedir, ".cache", "scratchpad")

	return scratchpadDir, nil
}
