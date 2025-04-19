export const processProfileData = (profileData, timestamp) => {
  try {
    const accountImages = [];
    const accountStats = [];
    const postDetails = [];
    const postStats = [];

    profileData.forEach((post) => {
      // Skip error items
      if (post.error || post.noResults) {
        console.log("Skipping error item:", post);
        return;
      }

      const postId = post.id ? post.id.toString() : null;
      const accountId = post.channel.id ? post.channel.id.toString() : null;

      // Add account data if not exists
      if (!accountImages.some((a) => a.account_id === accountId)) {
        accountImages.push({
          account_id: accountId,
          image_url: post.channel.avatar || null,
        });

        accountStats.push({
          account_id: accountId,
          follower_count: post.channel.followers || null,
          post_count: post.channel.videos || null,
          timestamp: timestamp,
        });
      }

      // Add post data if not exists
      if (!postDetails.some((p) => p.post_id === postId)) {
        postDetails.push({
          post_id: postId,
          account_id: accountId,
          created_at: post.uploadedAtFormatted || null,
          media_type: "video", // TikTok posts are always videos
          post_caption: post.title || null,
          image_url: post.video?.thumbnail || null,
          video_duration: post.video?.duration || null,
          post_url: post.postPage || null,
        });

        postStats.push({
          post_id: postId,
          like_count: post.likes < 4 ? null : post.likes,
          comment_count: post.comments === 0 ? null : post.comments,
          play_count: post.views || null,
          share_count: post.shares || null,
          bookmark_count: post.bookmarks || null,
          timestamp: timestamp,
        });
      }
    });

    return {
      success: true,
      data: {
        accountImages,
        accountStats,
        postDetails,
        postStats,
      },
      error: null,
    };
  } catch (error) {
    console.error("Error processing profile data:", error);
    return {
      success: false,
      data: null,
      error:
        error instanceof Error
          ? error.message
          : "Unknown error processing profile data",
    };
  }
};
