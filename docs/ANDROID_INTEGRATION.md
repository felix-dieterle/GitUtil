# Android Integration Guide

## Minimal Android Setup

This guide shows how to integrate the shell scripts into an Android app with minimal code.

## Step 1: Create Android Project Structure

```
android-shell/
├── AndroidManifest.xml
├── build.gradle  
└── src/
    └── ShellGitApp.kt (single-file app)
```

## Step 2: Copy Scripts to Assets

The shell scripts should be copied to `android-shell/assets/scripts/` during build and then extracted to app's cache directory at runtime.

## Step 3: Single-File Application Pattern

Instead of multiple Activities, use a single-file tabbed approach:

```kotlin
// ShellGitApp.kt - Complete app in one file
class ShellGitApp : Activity() {
    
    enum class Screen { PICKER, HISTORY }
    private var currentScreen = Screen.PICKER
    private var repoPath = ""
    private val scriptDir by lazy { 
        File(cacheDir, "scripts").also { it.mkdirs() }
    }
    
    override fun onCreate(saved: Bundle?) {
        super.onCreate(saved)
        extractScripts()
        renderCurrentScreen()
    }
    
    fun extractScripts() {
        // Copy from assets to cache
    }
    
    fun executeScript(scriptName: String, vararg args: String): String {
        // Run script and return output
    }
    
    fun renderCurrentScreen() {
        when (currentScreen) {
            Screen.PICKER -> showPickerUI()
            Screen.HISTORY -> showHistoryUI()
        }
    }
    
    fun showPickerUI() {
        // Build UI programmatically
    }
    
    fun showHistoryUI() {
        // Parse commit list and display
    }
}
```

## Step 4: Script Execution Pattern

```kotlin
fun runGitScript(scriptFile: String, vararg parameters: String): Pair<Int, String> {
    val scriptPath = File(scriptDir, scriptFile)
    val command = mutableListOf("sh", scriptPath.absolutePath)
    command.addAll(parameters)
    
    val processBuilder = ProcessBuilder(command)
    val process = processBuilder.start()
    
    val output = process.inputStream.bufferedReader().readText()
    val exitCode = process.waitFor()
    
    return Pair(exitCode, output)
}
```

## Step 5: Parse Commit Output

```kotlin
fun parseCommitData(rawOutput: String): List<Map<String, String>> {
    val commits = mutableListOf<Map<String, String>>()
    var currentCommit = mutableMapOf<String, String>()
    
    rawOutput.lines().forEach { line ->
        when {
            line == "COMMIT_START" -> currentCommit = mutableMapOf()
            line == "COMMIT_END" -> {
                commits.add(currentCommit)
                currentCommit = mutableMapOf()
            }
            line.contains(":") -> {
                val (key, value) = line.split(":", limit = 2)
                currentCommit[key] = value
            }
        }
    }
    
    return commits
}
```

This approach avoids standard Android patterns and uses a unique shell-wrapper architecture.
