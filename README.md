# Windows Performance Optimizer

A PowerShell-based Windows performance diagnostics and maintenance toolkit developed as part of my Microsoft Software & Systems Academy (MSSA) Server & Cloud Administration training.

## Project Overview

The Windows Performance Optimizer is an interactive PowerShell application designed to help users monitor system resources, identify potential performance bottlenecks, and perform basic system maintenance.

The application provides a simple command-line menu that combines several common Windows administration tasks into one tool.

## Features

### 1. System Performance Monitoring
- Displays operating system information and system uptime.
- Reports approximate CPU utilization.
- Shows total, used, and available RAM.
- Warns when memory usage exceeds 90%.

### 2. Resource-Heavy Process Analysis
- Identifies the 10 processes using the most physical memory.
- Displays process IDs and memory usage.
- Reports accumulated CPU time for each process.

### 3. Disk Space Analysis
- Displays total and available storage for local drives.
- Calculates available disk space percentages.
- Warns when free space falls below 15%.

### 4. Temporary File Analysis and Cleanup
- Analyzes files older than seven days in the current user's temporary folder.
- Estimates potential storage savings.
- Requests explicit confirmation before deleting eligible files.
- Reports the number of files deleted and approximate space recovered.
- Does not recursively delete temporary subfolders.

### 5. Startup Application Analysis
- Displays startup application information using Windows Management Instrumentation.
- Lists application names, locations, users, and startup commands.
- Does not modify startup settings.

### 6. Automated Performance Reporting
- Generates timestamped CSV reports.
- Records computer name, operating system, CPU load, memory usage, and disk information.
- Saves reports to a local `Reports` folder.

## Technologies Used

- Windows PowerShell
- Windows Management Instrumentation (WMI/CIM)
- Visual Studio Code
- Git and GitHub
- Windows process management
- CSV reporting

## How to Run

**Requirements:**
- Windows 10 or Windows 11
- Windows PowerShell 5.1
- Appropriate permissions to read system information

1. Clone or download the repository.
2. Open the project folder in Visual Studio Code.
3. Open a PowerShell terminal.
4. Execute:

```powershell
.\PerformanceOptimizer.ps1

