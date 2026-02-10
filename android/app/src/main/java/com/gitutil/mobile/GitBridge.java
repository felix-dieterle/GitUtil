package com.gitutil.mobile;

import android.util.Log;
import android.webkit.JavascriptInterface;

import org.eclipse.jgit.api.Git;
import org.eclipse.jgit.api.PushCommand;
import org.eclipse.jgit.api.ResetCommand;
import org.eclipse.jgit.lib.ObjectId;
import org.eclipse.jgit.lib.Repository;
import org.eclipse.jgit.revwalk.RevCommit;
import org.eclipse.jgit.revwalk.RevWalk;
import org.eclipse.jgit.storage.file.FileRepositoryBuilder;
import org.eclipse.jgit.transport.RefSpec;
import org.eclipse.jgit.transport.UsernamePasswordCredentialsProvider;
import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

/**
 * Bridge between JavaScript interface and JGit library
 * Provides git operations without external dependencies
 */
public class GitBridge {
    private static final String TAG = "GitBridge";
    private static final String DEFAULT_WORKSPACE_PATH = "/sdcard/GitUtil/repos";

    @JavascriptInterface
    public String executeWrapper(String wrapperName, String argsJson) {
        try {
            JSONArray args = new JSONArray(argsJson);
            
            switch (wrapperName) {
                case "check-location":
                    return checkLocation(args.getString(0));
                case "pull-timeline":
                    return pullTimeline(args.getString(0));
                case "apply-rollback":
                    // Optional third parameter: GitHub token for authentication
                    String token = args.length() > 2 ? args.getString(2) : null;
                    return applyRollback(args.getString(0), args.getString(1), token);
                case "get-default-workspace":
                    return getDefaultWorkspace();
                case "ensure-workspace":
                    return ensureWorkspace();
                case "list-repositories":
                    return listRepositories(args.length() > 0 ? args.getString(0) : DEFAULT_WORKSPACE_PATH);
                case "clone-repository":
                    return cloneRepository(args.getString(0), args.length() > 1 ? args.getString(1) : null);
                case "list-github-repos":
                    return listGitHubRepositories(args.getString(0));
                case "cleanup-repository":
                    return cleanupRepository(args.getString(0));
                default:
                    return createErrorResponse("Unknown wrapper: " + wrapperName);
            }
        } catch (Exception e) {
            Log.e(TAG, "Error executing wrapper", e);
            return createErrorResponse("Error: " + e.getMessage());
        }
    }

    /**
     * Helper method to open a git repository
     * Reduces code duplication and ensures consistent error handling
     */
    private Repository openRepository(String path) throws Exception {
        File gitDir = new File(path, ".git");
        if (!gitDir.exists() || !gitDir.isDirectory()) {
            gitDir = new File(path);
        }

        return new FileRepositoryBuilder()
            .setGitDir(gitDir.getName().equals(".git") ? gitDir : new File(path, ".git"))
            .readEnvironment()
            .findGitDir()
            .build();
    }

    private String checkLocation(String path) {
        try (Repository repository = openRepository(path)) {
            if (repository.getObjectDatabase().exists()) {
                return createSuccessResponse("LOCATION_VALID\n");
            } else {
                return createErrorResponse("LOCATION_INVALID\n");
            }
        } catch (Exception e) {
            Log.e(TAG, "Error checking location", e);
            return createErrorResponse("LOCATION_INVALID\n");
        }
    }

    private String pullTimeline(String path) {
        try (Repository repository = openRepository(path)) {
            StringBuilder output = new StringBuilder();
            
            try (Git git = new Git(repository)) {
                Iterable<RevCommit> commits = git.log().setMaxCount(100).call();
                
                for (RevCommit commit : commits) {
                    output.append("SNAPSHOT_BEGIN\n");
                    output.append("IDENTIFIER:").append(commit.getName()).append("\n");
                    output.append("CONTRIBUTOR:").append(commit.getAuthorIdent().getName()).append("\n");
                    output.append("WHEN:").append(commit.getCommitTime()).append("\n");
                    output.append("TITLE:").append(commit.getShortMessage()).append("\n");
                    output.append("SNAPSHOT_END\n");
                }
            }
            
            return createSuccessResponse(output.toString());
        } catch (Exception e) {
            Log.e(TAG, "Error pulling timeline", e);
            return createErrorResponse("Failed to fetch commits: " + e.getMessage());
        }
    }

    /**
     * Apply rollback to a specific commit with step tracking and transactional behavior
     * 
     * This implementation performs a hard reset to the specified commit and pushes the changes
     * to the remote repository (if configured). All commits after the selected commit will be
     * removed from both local and remote history.
     * 
     * @param path Repository path
     * @param commitHash Target commit hash
     * @param githubToken Optional GitHub personal access token for authentication (can be null)
     * @return JSON response with success or error and step tracking information
     */
    private String applyRollback(String path, String commitHash, String githubToken) {
        // Create SimpleDateFormat locally to ensure thread safety
        SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US);
        StringBuilder stepOutput = new StringBuilder();
        
        Log.i(TAG, "========================================");
        Log.i(TAG, "Apply Rollback Operation Started");
        Log.i(TAG, "========================================");
        Log.i(TAG, "Timestamp: " + dateFormat.format(new Date()));
        Log.i(TAG, "Repository Path: " + path);
        Log.i(TAG, "Target Commit: " + commitHash);
        
        String backupBranchName = null;
        ObjectId currentHead = null;
        
        try (Repository repository = openRepository(path)) {
            // Step 1: Validate repository
            stepOutput.append("STEP_STATUS:validate:in_progress\n");
            Log.i(TAG, "Validating repository...");
            
            if (!repository.getObjectDatabase().exists()) {
                stepOutput.append("STEP_STATUS:validate:failed\n");
                Log.e(TAG, "ERROR: Repository validation failed");
                return createErrorResponse(stepOutput.toString(), "ROLLBACK_FAILED\nInvalid repository");
            }
            
            Log.i(TAG, "Repository validated successfully");
            
            try (Git git = new Git(repository)) {
                Log.i(TAG, "Verifying commit exists in repository...");
                ObjectId commitId = repository.resolve(commitHash);
                if (commitId == null) {
                    stepOutput.append("STEP_STATUS:validate:failed\n");
                    stepOutput.append("STEP_DETAIL:Commit ").append(commitHash).append(" not found\n");
                    Log.e(TAG, "ERROR: Commit verification failed");
                    Log.e(TAG, "Commit " + commitHash + " not found in this repository");
                    return createErrorResponse(stepOutput.toString(), "ROLLBACK_FAILED\nCommit not found: " + commitHash);
                }
                Log.i(TAG, "✓ Commit " + commitHash + " verified");
                stepOutput.append("STEP_DETAIL:Commit verified: ").append(commitHash, 0, Math.min(commitHash.length(), 8)).append("\n");
                stepOutput.append("STEP_STATUS:validate:completed\n");
                
                // Step 2: Create backup branch
                stepOutput.append("STEP_STATUS:backup:in_progress\n");
                currentHead = repository.resolve("HEAD");
                Log.i(TAG, "Current HEAD: " + (currentHead != null ? currentHead.getName() : "unknown"));
                
                if (currentHead == null) {
                    stepOutput.append("STEP_STATUS:backup:failed\n");
                    stepOutput.append("STEP_DETAIL:Could not determine current HEAD\n");
                    Log.e(TAG, "ERROR: Could not determine current HEAD");
                    return createErrorResponse(stepOutput.toString(), "ROLLBACK_FAILED\nCould not determine current HEAD");
                }
                
                // SimpleDateFormat created locally for immediate use - thread-safe in this context
                SimpleDateFormat timestampFormat = new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US);
                String timestamp = timestampFormat.format(new Date());
                backupBranchName = "backup/before-rollback-" + timestamp;
                Log.i(TAG, "Creating backup branch: " + backupBranchName);
                stepOutput.append("STEP_DETAIL:Creating backup branch: ").append(backupBranchName).append("\n");
                
                try {
                    git.branchCreate()
                        .setName(backupBranchName)
                        .setStartPoint(currentHead.getName())
                        .call();
                    Log.i(TAG, "✓ Backup branch created successfully: " + backupBranchName);
                    stepOutput.append("STEP_DETAIL:Backup branch created successfully\n");
                    stepOutput.append("STEP_STATUS:backup:completed\n");
                } catch (Exception branchEx) {
                    stepOutput.append("STEP_STATUS:backup:failed\n");
                    stepOutput.append("STEP_DETAIL:Failed to create backup branch\n");
                    Log.e(TAG, "ERROR: Failed to create backup branch");
                    Log.e(TAG, "Backup branch error: " + (branchEx.getMessage() != null ? branchEx.getMessage() : "unknown"));
                    return createErrorResponse(stepOutput.toString(), "ROLLBACK_FAILED\nFailed to create backup branch");
                }
                
                // Step 3: Reset to target commit
                stepOutput.append("STEP_STATUS:reset:in_progress\n");
                Log.i(TAG, "Executing hard reset to: " + commitHash);
                stepOutput.append("STEP_DETAIL:Reverting branch to commit: ").append(commitHash, 0, Math.min(commitHash.length(), 8)).append("\n");
                
                try {
                    git.reset()
                        .setMode(ResetCommand.ResetType.HARD)
                        .setRef(commitHash)
                        .call();
                    
                    // Get new HEAD
                    ObjectId newHead = repository.resolve("HEAD");
                    Log.i(TAG, "✓ Reset successful");
                    Log.i(TAG, "Previous HEAD: " + (currentHead != null ? currentHead.getName() : "unknown"));
                    Log.i(TAG, "New HEAD: " + (newHead != null ? newHead.getName() : "unknown"));
                    stepOutput.append("STEP_DETAIL:Reset successful\n");
                    stepOutput.append("STEP_STATUS:reset:completed\n");
                } catch (Exception resetEx) {
                    stepOutput.append("STEP_STATUS:reset:failed\n");
                    stepOutput.append("STEP_DETAIL:Git reset failed\n");
                    Log.e(TAG, "ERROR: Git reset failed");
                    
                    // Rollback: Restore from backup branch
                    rollbackToBackup(git, backupBranchName, currentHead, stepOutput);
                    
                    String errorMsg = resetEx.getMessage() != null ? resetEx.getMessage() : resetEx.getClass().getSimpleName();
                    return createErrorResponse(stepOutput.toString(), "ROLLBACK_FAILED\n" + errorMsg);
                }
                
                // Step 4: Push to remote
                stepOutput.append("STEP_STATUS:push:in_progress\n");
                String currentBranch = repository.getBranch();
                stepOutput.append("STEP_DETAIL:Pushing changes to remote branch: ").append(currentBranch).append("\n");
                Log.i(TAG, "Current branch: " + currentBranch);
                
                // Check if remote exists
                if (git.remoteList().call().stream().anyMatch(remote -> remote.getName().equals("origin"))) {
                    try {
                        // Push with force since we're intentionally rewriting history
                        // The rollback operation is an explicit user action to remove commits
                        // Using explicit PushCommand type for Java 8 compatibility
                        PushCommand pushCommand = git.push()
                            .setRemote("origin")
                            .setRefSpecs(new RefSpec(currentBranch + ":" + currentBranch))
                            .setForce(true);
                        
                        // Add credentials if GitHub token is provided
                        if (githubToken != null && !githubToken.trim().isEmpty()) {
                            Log.i(TAG, "Using provided GitHub token for authentication");
                            // GitHub personal access tokens should be used as password with a dummy username
                            pushCommand.setCredentialsProvider(
                                new UsernamePasswordCredentialsProvider("x-access-token", githubToken)
                            );
                        }
                        
                        pushCommand.call();
                        
                        Log.i(TAG, "✓ Successfully pushed to remote");
                        stepOutput.append("STEP_STATUS:push:completed\n");
                        stepOutput.append("STEP_DETAIL:Successfully pushed to remote\n");
                    } catch (Exception pushEx) {
                        String errorMsg = pushEx.getMessage() != null ? pushEx.getMessage() : pushEx.getClass().getSimpleName();
                        
                        // Check if this is an authentication error by examining exception type and message
                        // JGit throws TransportException for authentication failures
                        boolean isAuthError = (pushEx.getClass().getName().contains("TransportException") ||
                                             pushEx.getClass().getName().contains("InvalidRemoteException")) &&
                                            (errorMsg.contains("Authentication") || 
                                             errorMsg.contains("CredentialsProvider") ||
                                             errorMsg.contains("not authorized") ||
                                             errorMsg.contains("authentication failed") ||
                                             errorMsg.contains("Authentication is required"));
                        
                        if (isAuthError) {
                            // Authentication failed - keep local changes but warn user
                            stepOutput.append("STEP_STATUS:push:failed\n");
                            stepOutput.append("STEP_DETAIL:Push failed due to authentication\n");
                            stepOutput.append("STEP_DETAIL:Local rollback succeeded - remote was not updated\n");
                            stepOutput.append("STEP_DETAIL:To push manually, use: git push --force-with-lease origin ").append(currentBranch).append("\n");
                            Log.w(TAG, "⚠ Push failed due to authentication - local rollback succeeded");
                            Log.w(TAG, "Authentication error: " + errorMsg);
                            Log.i(TAG, "Local rollback completed successfully");
                            Log.i(TAG, "Note: Remote repository was not updated");
                            Log.i(TAG, "Backup branch retained: " + backupBranchName);
                            
                            // Return success since local rollback worked, just with a warning about remote
                            Log.i(TAG, "========================================");
                            return createSuccessResponse(stepOutput.toString() + "ROLLBACK_SUCCESS_LOCAL_ONLY: " + commitHash);
                        } else {
                            // Other push error - rollback the changes to maintain consistency
                            stepOutput.append("STEP_STATUS:push:failed\n");
                            stepOutput.append("STEP_DETAIL:Push to remote failed\n");
                            Log.e(TAG, "ERROR: Push to remote failed");
                            Log.e(TAG, "Push error: " + errorMsg);
                            
                            // Rollback: Restore from backup branch
                            rollbackToBackup(git, backupBranchName, currentHead, stepOutput);
                            
                            return createErrorResponse(stepOutput.toString(), "ROLLBACK_FAILED\nPush to remote failed - changes rolled back\n" + errorMsg);
                        }
                    }
                } else {
                    // No remote configured - skip push and succeed
                    stepOutput.append("STEP_STATUS:push:completed\n");
                    stepOutput.append("STEP_DETAIL:No remote configured - push skipped\n");
                    Log.i(TAG, "No remote configured - push skipped");
                }
                
                // Success - keep backup branch for user reference (not deleted on success)
                Log.i(TAG, "Backup branch retained: " + backupBranchName);
                
                Log.i(TAG, "========================================");
                return createSuccessResponse(stepOutput.toString() + "ROLLBACK_SUCCESS: " + commitHash);
            }
        } catch (Exception e) {
            Log.e(TAG, "❌ Rollback failed");
            Log.e(TAG, "Exception type: " + e.getClass().getName());
            Log.e(TAG, "Exception message: " + (e.getMessage() != null ? e.getMessage() : "null"));
            Log.e(TAG, "========================================");
            
            String errorMsg = e.getMessage() != null ? e.getMessage() : e.getClass().getSimpleName();
            return createErrorResponse(stepOutput.toString(), "ROLLBACK_FAILED\n" + errorMsg);
        }
    }

    /**
     * Helper method to rollback changes by restoring from backup branch
     * Called when a step in the transaction fails
     */
    private void rollbackToBackup(Git git, String backupBranchName, ObjectId originalHead, StringBuilder stepOutput) {
        stepOutput.append("STEP_DETAIL:Transaction failed - initiating rollback\n");
        Log.w(TAG, "Transaction failed - attempting to restore from backup");
        
        try {
            if (backupBranchName != null && git.getRepository().resolve(backupBranchName) != null) {
                stepOutput.append("STEP_DETAIL:Restoring from backup branch: ").append(backupBranchName).append("\n");
                Log.i(TAG, "Restoring from backup branch: " + backupBranchName);
                
                git.reset()
                    .setMode(ResetCommand.ResetType.HARD)
                    .setRef(backupBranchName)
                    .call();
                
                // Delete the backup branch after restoring
                git.branchDelete()
                    .setBranchNames(backupBranchName)
                    .setForce(true)
                    .call();
                
                String headStr = originalHead != null ? originalHead.getName().substring(0, 8) : "unknown";
                stepOutput.append("STEP_DETAIL:State restored to original HEAD: ").append(headStr).append("\n");
                Log.i(TAG, "State restored to original HEAD: " + headStr);
            } else {
                stepOutput.append("STEP_DETAIL:Backup branch not available for restoration\n");
                Log.w(TAG, "Backup branch not available for restoration");
            }
        } catch (Exception rollbackEx) {
            stepOutput.append("STEP_DETAIL:Warning: Rollback restoration failed\n");
            Log.e(TAG, "Error during rollback restoration: " + rollbackEx.getMessage());
        }
    }

    /**
     * Get the default workspace path
     */
    private String getDefaultWorkspace() {
        return createSuccessResponse(DEFAULT_WORKSPACE_PATH);
    }

    /**
     * Ensure the default workspace directory exists
     */
    private String ensureWorkspace() {
        try {
            File workspaceDir = new File(DEFAULT_WORKSPACE_PATH);
            if (!workspaceDir.exists()) {
                if (workspaceDir.mkdirs()) {
                    return createSuccessResponse("WORKSPACE_CREATED:" + DEFAULT_WORKSPACE_PATH);
                } else {
                    return createErrorResponse("Failed to create workspace directory");
                }
            }
            return createSuccessResponse("WORKSPACE_EXISTS:" + DEFAULT_WORKSPACE_PATH);
        } catch (Exception e) {
            Log.e(TAG, "Error ensuring workspace", e);
            return createErrorResponse("Error creating workspace: " + e.getMessage());
        }
    }

    /**
     * List all git repositories in the specified directory
     */
    private String listRepositories(String workspacePath) {
        try {
            File workspace = new File(workspacePath);
            if (!workspace.exists() || !workspace.isDirectory()) {
                return createSuccessResponse("REPOS_BEGIN\nREPOS_END");
            }

            StringBuilder output = new StringBuilder();
            output.append("REPOS_BEGIN\n");

            File[] files = workspace.listFiles();
            if (files != null) {
                for (File file : files) {
                    if (file.isDirectory()) {
                        File gitDir = new File(file, ".git");
                        if (gitDir.exists() && gitDir.isDirectory()) {
                            output.append("REPO_NAME:").append(file.getName()).append("\n");
                            output.append("REPO_PATH:").append(file.getAbsolutePath()).append("\n");
                            output.append("REPO_SEPARATOR\n");
                        }
                    }
                }
            }

            output.append("REPOS_END");
            return createSuccessResponse(output.toString());
        } catch (Exception e) {
            Log.e(TAG, "Error listing repositories", e);
            return createErrorResponse("Error listing repositories: " + e.getMessage());
        }
    }

    /**
     * Clone a git repository from URL to workspace
     */
    private String cloneRepository(String url, String targetName) {
        try {
            // Extract repository name from URL if target name not provided
            if (targetName == null || targetName.trim().isEmpty()) {
                targetName = extractRepoName(url);
            }

            File workspaceDir = new File(DEFAULT_WORKSPACE_PATH);
            if (!workspaceDir.exists()) {
                workspaceDir.mkdirs();
            }

            File targetDir = new File(workspaceDir, targetName);
            if (targetDir.exists()) {
                return createErrorResponse("Repository directory already exists: " + targetName);
            }

            Log.i(TAG, "Cloning repository from " + url + " to " + targetDir.getAbsolutePath());
            
            Git.cloneRepository()
                .setURI(url)
                .setDirectory(targetDir)
                .call();

            return createSuccessResponse("CLONE_SUCCESS:" + targetDir.getAbsolutePath());
        } catch (Exception e) {
            Log.e(TAG, "Error cloning repository", e);
            return createErrorResponse("CLONE_FAILED\n" + e.getMessage());
        }
    }

    /**
     * Extract repository name from git URL
     */
    private String extractRepoName(String url) {
        String name = url;
        // Remove trailing .git
        if (name.endsWith(".git")) {
            name = name.substring(0, name.length() - 4);
        }
        // Get last path segment
        int lastSlash = name.lastIndexOf('/');
        if (lastSlash >= 0) {
            name = name.substring(lastSlash + 1);
        }
        // Remove any invalid characters
        name = name.replaceAll("[^a-zA-Z0-9._-]", "_");
        return name;
    }

    /**
     * List GitHub repositories using personal access token
     */
    private String listGitHubRepositories(String token) {
        try {
            StringBuilder output = new StringBuilder();
            output.append("GITHUB_REPOS_BEGIN\n");

            // GitHub API endpoint for user repositories
            URL url = new URL("https://api.github.com/user/repos?per_page=100&sort=updated");
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("GET");
            conn.setRequestProperty("Authorization", "token " + token);
            conn.setRequestProperty("Accept", "application/vnd.github.v3+json");
            conn.setConnectTimeout(10000);
            conn.setReadTimeout(10000);

            int responseCode = conn.getResponseCode();
            if (responseCode == 200) {
                try (BufferedReader reader = new BufferedReader(
                        new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8))) {
                    StringBuilder response = new StringBuilder();
                    String line;
                    while ((line = reader.readLine()) != null) {
                        response.append(line);
                    }

                    // Parse JSON response
                    JSONArray repos = new JSONArray(response.toString());
                    for (int i = 0; i < repos.length(); i++) {
                        JSONObject repo = repos.getJSONObject(i);
                        String repoName = repo.getString("name");
                        String repoFullName = repo.getString("full_name");
                        String cloneUrl = repo.getString("clone_url");
                        String description = repo.optString("description", "");
                        boolean isPrivate = repo.getBoolean("private");

                        output.append("GITHUB_REPO_NAME:").append(repoName).append("\n");
                        output.append("GITHUB_REPO_FULLNAME:").append(repoFullName).append("\n");
                        output.append("GITHUB_REPO_URL:").append(cloneUrl).append("\n");
                        output.append("GITHUB_REPO_DESC:").append(description).append("\n");
                        output.append("GITHUB_REPO_PRIVATE:").append(isPrivate).append("\n");
                        output.append("GITHUB_REPO_SEPARATOR\n");
                    }
                }
            } else if (responseCode == 401) {
                return createErrorResponse("Invalid GitHub token. Please check your token and try again.");
            } else {
                return createErrorResponse("GitHub API error: HTTP " + responseCode);
            }

            output.append("GITHUB_REPOS_END");
            return createSuccessResponse(output.toString());
        } catch (Exception e) {
            Log.e(TAG, "Error listing GitHub repositories", e);
            return createErrorResponse("Error connecting to GitHub: " + e.getMessage());
        }
    }

    /**
     * Cleanup (delete) a repository from the workspace
     */
    private String cleanupRepository(String path) {
        try {
            File repoDir = new File(path);
            
            // Check if directory exists
            if (!repoDir.exists()) {
                return createErrorResponse("Directory does not exist: " + path);
            }
            
            if (!repoDir.isDirectory()) {
                return createErrorResponse("Path is not a directory: " + path);
            }
            
            // Security: Resolve canonical path to prevent directory traversal
            String canonicalPath = repoDir.getCanonicalPath();
            File workspaceDir = new File(DEFAULT_WORKSPACE_PATH);
            String workspaceCanonicalPath = workspaceDir.getCanonicalPath();
            
            // Verify the repository is within the workspace to prevent deleting arbitrary files
            if (!canonicalPath.startsWith(workspaceCanonicalPath)) {
                Log.w(TAG, "Attempted to delete repository outside workspace: " + canonicalPath);
                return createErrorResponse("Security: Can only delete repositories within workspace");
            }
            
            // Verify it's a git repository
            File gitDir = new File(repoDir, ".git");
            if (!gitDir.exists() || !gitDir.isDirectory()) {
                return createErrorResponse("Not a git repository: " + path);
            }
            
            Log.i(TAG, "Deleting repository: " + canonicalPath);
            
            // Delete the repository recursively
            if (deleteRecursively(repoDir)) {
                return createSuccessResponse("CLEANUP_SUCCESS:" + path);
            } else {
                return createErrorResponse("Failed to delete repository: " + path);
            }
        } catch (Exception e) {
            Log.e(TAG, "Error cleaning up repository", e);
            return createErrorResponse("Error deleting repository: " + e.getMessage());
        }
    }
    
    /**
     * Recursively delete a directory and all its contents
     */
    private boolean deleteRecursively(File file) {
        if (file.isDirectory()) {
            File[] children = file.listFiles();
            if (children != null) {
                for (File child : children) {
                    if (!deleteRecursively(child)) {
                        return false;
                    }
                }
            }
        }
        return file.delete();
    }

    private String createSuccessResponse(String output) {
        try {
            JSONObject response = new JSONObject();
            response.put("success", true);
            response.put("output", output);
            response.put("errors", "");
            response.put("exit_code", 0);
            return response.toString();
        } catch (Exception e) {
            Log.e(TAG, "Error creating success response", e);
            return "{\"success\":false,\"output\":\"\",\"errors\":\"" + e.getMessage() + "\",\"exit_code\":1}";
        }
    }

    private String createErrorResponse(String error) {
        return createErrorResponse("", error);
    }

    private String createErrorResponse(String output, String error) {
        try {
            JSONObject response = new JSONObject();
            response.put("success", false);
            response.put("output", output);
            response.put("errors", error);
            response.put("exit_code", 1);
            return response.toString();
        } catch (Exception e) {
            Log.e(TAG, "Error creating error response", e);
            return "{\"success\":false,\"output\":\"\",\"errors\":\"" + e.getMessage() + "\",\"exit_code\":1}";
        }
    }
}
