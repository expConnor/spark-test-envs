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
      like_count: post.likes < 4 ? null : post.likes,
      comment_count: post.comments === 0 ? null : post.comments,
      play_count: post.views || null,
      share_count: post.shares || null,
      bookmark_count: post.bookmarks || null,
      timestamp: timestamp,
    };
  });
};
