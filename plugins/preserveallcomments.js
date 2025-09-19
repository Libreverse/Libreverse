import * as acorn from "acorn";

export default function preserveAllComments() {
    return {
        name: "preserve-all-comments",
        enforce: "post", // Run after other plugins
        generateBundle(options, bundle) {
            for (const fileName in bundle) {
                const item = bundle[fileName];
                if (item.type === "chunk") {
                    // For JS chunks
                    const comments = [];
                    try {
                        acorn.parse(item.code, {
                            onComment: comments,
                            locations: true,
                            sourceType: "module",
                            ecmaVersion: "latest",
                        });
                    } catch (error) {
                        console.warn(
                            `Failed to parse ${fileName} for comments: ${error.message}`,
                        );
                        continue;
                    }

                    // Sort comments in descending order of start position to avoid offset issues
                    comments.sort((a, b) => b.start - a.start);

                    let newCode = item.code;
                    for (const comment of comments) {
                        const insertPos = comment.start + 2; // After /* or //
                        newCode =
                            newCode.slice(0, insertPos) +
                            "!" +
                            newCode.slice(insertPos);
                    }
                    item.code = newCode;
                }
            }
        },
    };
}
