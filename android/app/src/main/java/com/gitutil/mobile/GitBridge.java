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

import java.io.File;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

/**
 * Bridge between JavaScript interface and JGit library
 * Provides git operations without external dependencies
 */
public class GitBridge {
    private static final String TAG = "GitBridge";

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
                default:
                    return createErrorResponse("Unknown wrapper: " + wrapperName);
            }
        } catch (Exception e) {
            Log.e(TAG, "Error executing wrapper", e);
            return createErrorResponse("Error: " + e.getMessage());
        }
    }

    private String checkLocation(String path) {
        try {
            File gitDir = new File(path, ".git");
            if (!gitDir.exists() || !gitDir.isDirectory()) {
                // Try the path itself as a .git directory
                gitDir = new File(path);
            }

            FileRepositoryBuilder builder = new FileRepositoryBuilder();
            Repository repository = builder
                .setGitDir(gitDir.getName().equals(".git") ? gitDir : new File(path, ".git"))
                .readEnvironment()
                .findGitDir()
                .build();
            
            if (repository.getObjectDatabase().exists()) {
                repository.close();
                return createSuccessResponse("LOCATION_VALID\n");
            } else {
                repository.close();
                return createErrorResponse("LOCATION_INVALID\n");
            }
        } catch (Exception e) {
            Log.e(TAG, "Error checking location", e);
            return createErrorResponse("LOCATION_INVALID\n");
        }
    }

    private String pullTimeline(String path) {
        try {
            File gitDir = new File(path, ".git");
            if (!gitDir.exists() || !gitDir.isDirectory()) {
                gitDir = new File(path);
            }

            FileRepositoryBuilder builder = new FileRepositoryBuilder();
            Repository repository = builder
                .setGitDir(gitDir.getName().equals(".git") ? gitDir : new File(path, ".git"))
                .readEnvironment()
                .findGitDir()
                .build();

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
            
            repository.close();
            return createSuccessResponse(output.toString());
        } catch (Exception e) {
            Log.e(TAG, "Error pulling timeline", e);
            return createErrorResponse("Failed to fetch commits: " + e.getMessage());
        }
    }

    private String applyRollback(String path, String commitHash) {
        try {
            File gitDir = new File(path, ".git");
            if (!gitDir.exists() || !gitDir.isDirectory()) {
                gitDir = new File(path);
            }

            FileRepositoryBuilder builder = new FileRepositoryBuilder();
            Repository repository = builder
                .setGitDir(gitDir.getName().equals(".git") ? gitDir : new File(path, ".git"))
                .readEnvironment()
                .findGitDir()
                .build();

            try (Git git = new Git(repository)) {
                ObjectId commitId = repository.resolve(commitHash);
                if (commitId == null) {
                    repository.close();
                    return createErrorResponse("ROLLBACK_FAILED\nCommit not found");
                }
                
                git.reset()
                    .setMode(ResetCommand.ResetType.HARD)
                    .setRef(commitHash)
                    .call();
                
                repository.close();
                return createSuccessResponse("ROLLBACK_SUCCESS\n");
            }
        } catch (Exception e) {
            Log.e(TAG, "Error applying rollback", e);
            return createErrorResponse("ROLLBACK_FAILED\n" + e.getMessage());
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
