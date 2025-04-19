export const processPostData = (rawData, timestamp) => {
  if (!Array.isArray(rawData)) {
    console.error("Raw data is not an array");
    return [];
  }

  return rawData.map((post) => {
    // Ensure post_id is a string that can be safely converted to bigint
    const postId = post.id ? post.id.toString() : null;

    return {
      post_id: postId,
      like_count: post.likesCount < 4 ? null : post.likesCount,
      comment_count: post.commentsCount === 0 ? null : post.commentsCount,
      play_count: post.type === "Video" ? post.videoPlayCount || null : null,
      timestamp: timestamp,
    };
  });
};
