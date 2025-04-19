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

      const postId = post.id.split("_")[0];
      const accountId = post.owner.id;

      // Add account data if not exists
      if (!accountImages.some((a) => a.account_id === accountId)) {
        accountImages.push({
          account_id: accountId,
          image_url: post.owner.profilePicUrl,
        });

        accountStats.push({
          account_id: accountId,
          follower_count: post.owner.followerCount,
          post_count: post.owner.postCount,
          timestamp: timestamp,
        });
      }

      // Add post data if not exists
      if (!postDetails.some((p) => p.post_id === postId)) {
        postDetails.push({
          post_id: postId,
          account_id: accountId,
          created_at: post.createdAt,
          media_type: post.isVideo
            ? "video"
            : post.isCarousel
            ? "carousel"
            : "image",
          post_caption: post.caption,
          image_url: post.image?.url,
          video_duration: post.video?.duration || null,
          post_url: post.url,
        });

        postStats.push({
          post_id: postId,
          like_count: post.likeCount < 4 ? null : post.likeCount,
          comment_count: post.commentCount === 0 ? null : post.commentCount,
          play_count: post.video?.playCount || null,
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
