#!/usr/bin/env python3
"""
Graceful exit handler for CheckRef workflow.
Displays clean error messages and terminates the workflow gracefully.
"""

import sys
import os

def display_build_mismatch_message():
    """Display the graceful exit message for build mismatches."""
    print("")
    print("╔════════════════════════════════════════════════════════════════════════════════╗")
    print("║                           WORKFLOW TERMINATED                                 ║")
    print("║                        Genome Build Mismatch Detected                         ║")
    print("╚════════════════════════════════════════════════════════════════════════════════╝")
    print("")
    print("The CheckRef workflow has detected that your target VCF and reference legend")
    print("files are using different genome builds (e.g., hg19 vs hg38).")
    print("")
    print("This would produce incorrect allele switch detection results.")
    print("")
    print("Please fix this by:")
    print("• Using files with matching genome builds, OR")
    print("• Converting one file to match the other using liftOver tools")
    print("")
    print("Check the summary files in your output directory for detailed build information.")
    print("")

def main():
    if len(sys.argv) != 2:
        print("Usage: graceful_exit.py <summary_file>")
        sys.exit(1)
    
    summary_file = sys.argv[1]
    
    if not os.path.exists(summary_file):
        print(f"Error: Summary file {summary_file} not found")
        sys.exit(1)
    
    # Check if build mismatch was detected
    with open(summary_file, 'r') as f:
        content = f.read()
    
    if "GENOME BUILD MISMATCH" in content:
        display_build_mismatch_message()
        # Use a special mechanism to terminate the entire workflow
        # Create a flag file that the main workflow can detect
        with open("WORKFLOW_TERMINATED", 'w') as f:
            f.write("BUILD_MISMATCH_DETECTED\n")
        sys.exit(0)
    else:
        print("Build validation passed - continuing workflow")
        sys.exit(0)

if __name__ == "__main__":
    main()
