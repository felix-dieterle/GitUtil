package com.gitutil.mobile;

import android.util.Log;
import android.webkit.JavascriptInterface;

import org.eclipse.jgit.api.Git;
import org.eclipse.jgit.api.ResetCommand;
import org.eclipse.jgit.lib.ObjectId;
import org.eclipse.jgit.lib.Repository;
import org.eclipse.jgit.revwalk.RevCommit;
import org.eclipse.jgit.revwalk.RevWalk;
import org.eclipse.jgit.storage.file.FileRepositoryBuilder;
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
                    return applyRollback(args.getString(0), args.getString(1));
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

    private static final SimpleDateFormat DATE_FORMAT = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US);
    
    private String applyRollback(String path, String commitHash) {
        Log.i(TAG, "========================================");
        Log.i(TAG, "Apply Rollback Operation Started");
        Log.i(TAG, "========================================");
        Log.i(TAG, "Timestamp: " + DATE_FORMAT.format(new Date()));
        Log.i(TAG, "Repository Path: " + path);
        Log.i(TAG, "Target Commit: " + commitHash);
        
        try (Repository repository = openRepository(path)) {
            Log.i(TAG, "Repository opened successfully");
            
            try (Git git = new Git(repository)) {
                Log.i(TAG, "Verifying commit exists in repository...");
                ObjectId commitId = repository.resolve(commitHash);
                if (commitId == null) {
                    Log.e(TAG, "ERROR: Commit verification failed");
                    Log.e(TAG, "Commit " + commitHash + " not found in this repository");
                    return createErrorResponse("ROLLBACK_FAILED\nCommit not found: " + commitHash);
                }
                Log.i(TAG, "✓ Commit " + commitHash + " verified");
                
                // Get current HEAD for reference
                ObjectId currentHead = repository.resolve("HEAD");
                Log.i(TAG, "Current HEAD: " + (currentHead != null ? currentHead.getName() : "unknown"));
                
                Log.i(TAG, "Executing hard reset to: " + commitHash);
                git.reset()
                    .setMode(ResetCommand.ResetType.HARD)
                    .setRef(commitHash)
                    .call();
                
                // Get new HEAD
                ObjectId newHead = repository.resolve("HEAD");
                Log.i(TAG, "✓ Rollback successful");
                Log.i(TAG, "Previous HEAD: " + (currentHead != null ? currentHead.getName() : "unknown"));
                Log.i(TAG, "New HEAD: " + (newHead != null ? newHead.getName() : "unknown"));
                Log.i(TAG, "========================================");
                
                return createSuccessResponse("ROLLBACK_SUCCESS: " + commitHash);
            }
        } catch (Exception e) {
            Log.e(TAG, "❌ Rollback failed");
            Log.e(TAG, "Exception type: " + e.getClass().getName());
            Log.e(TAG, "Exception message: " + (e.getMessage() != null ? e.getMessage() : "null"));
            Log.e(TAG, "========================================");
            
            String errorMsg = e.getMessage() != null ? e.getMessage() : e.getClass().getSimpleName();
            return createErrorResponse("ROLLBACK_FAILED\n" + errorMsg);
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
        try {
            JSONObject response = new JSONObject();
            response.put("success", false);
            response.put("output", "");
            response.put("errors", error);
            response.put("exit_code", 1);
            return response.toString();
        } catch (Exception e) {
            Log.e(TAG, "Error creating error response", e);
            return "{\"success\":false,\"output\":\"\",\"errors\":\"" + e.getMessage() + "\",\"exit_code\":1}";
        }
    }
}
