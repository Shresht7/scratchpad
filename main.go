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

	// Set the scratchpad name if provided in arguments
	if len(os.Args) >= 1 {
		scratchpadName = os.Args[1]
	}

	// Show help if help was requested
	if scratchpadName == "help" || scratchpadName == "--help" || scratchpadName == "-h" {
		showHelp()
		os.Exit(0)
	}

	fmt.Println(scratchpadName, scratchpadDir)
}

// Shows the help message
func showHelp() {
	fmt.Println("Scratchpad")
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
