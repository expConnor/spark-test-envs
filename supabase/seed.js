const { createSeedClient } = require("@snaplet/seed");
const { copycat } = require("@snaplet/copycat");

async function main() {
  const seed = await createSeedClient({ dryRun: true });

  // Seed creator_db (10 creators)
  await seed.creator_db((x) =>
    x(10, {
      creator_id: (ctx) => ctx.index + 1,
      full_name: (ctx) => {
        const name = `${copycat.fullName(ctx.seed)}-${ctx.index}`;
        console.log(`Generating creator_db: ${name}`);
        return name;
      },
      image_url_cdn: (ctx) =>
        `https://picsum.photos/200/200?random=${copycat.int(ctx.seed, {
          min: 1,
          max: 1000,
        })}`,
      image_url: (ctx) =>
        `https://picsum.photos/200/200?random=${copycat.int(ctx.seed, {
          min: 1,
          max: 1000,
        })}`,
    })
  );

  // Seed instagram_account_db (2 accounts per creator)
  await seed.instagram_account_db((x) =>
    x(2, {
      creator_id: (ctx) => ctx.index + 1,
      username: (ctx) => `${copycat.username(ctx.seed)}-${ctx.index}`,
      account_url: (ctx) =>
        `https://instagram.com/${copycat.username(ctx.seed)}-${ctx.index}`,
      active: (ctx) => copycat.bool(ctx.seed),
    })
  );

  // Seed instagram_account_metrics (5 metrics per account)
  await seed.instagram_account_metrics((x) =>
    x(5, {
      timestamp: (ctx) =>
        copycat.dateString(ctx.seed, { minYear: 2020, maxYear: 2023 }),
      follower_count: (ctx) =>
        copycat.int(ctx.seed, { min: 1000, max: 1000000 }),
      post_count: (ctx) => copycat.int(ctx.seed, { min: 10, max: 1000 }),
    })
  );

  // Seed instagram_post_db (10 posts per account)
  await seed.instagram_post_db((x) =>
    x(10, {
      post_caption: (ctx) => copycat.sentence(ctx.seed),
      media_type: (ctx) => copycat.oneOf(ctx.seed, ["image", "video"]),
      image_url: (ctx) =>
        `https://picsum.photos/1080/1080?random=${copycat.int(ctx.seed, {
          min: 1,
          max: 1000,
        })}`,
      image_url_cdn: (ctx) =>
        `https://picsum.photos/1080/1080?random=${copycat.int(ctx.seed, {
          min: 1,
          max: 1000,
        })}`,
      video_duration: (ctx) => copycat.float(ctx.seed, { min: 1, max: 60 }),
      post_url: (ctx) => `https://instagram.com/p/${copycat.uuid(ctx.seed)}`,
      active: (ctx) => copycat.bool(ctx.seed),
    })
  );

  // Seed instagram_post_metrics (3 metrics per post)
  await seed.instagram_post_metrics((x) =>
    x(3, {
      like_count: (ctx) => copycat.int(ctx.seed, { min: 0, max: 10000 }),
      comment_count: (ctx) => copycat.int(ctx.seed, { min: 0, max: 1000 }),
      play_count: (ctx) => copycat.int(ctx.seed, { min: 0, max: 100000 }),
      timestamp: (ctx) =>
        copycat.dateString(ctx.seed, { minYear: 2020, maxYear: 2023 }),
    })
  );

  // Seed tiktok_account_db (1 account per creator)
  await seed.tiktok_account_db((x) =>
    x(1, {
      username: (ctx) => `${copycat.username(ctx.seed)}-${ctx.index}`,
      account_url: (ctx) =>
        `https://tiktok.com/@${copycat.username(ctx.seed)}-${ctx.index}`,
      active: (ctx) => copycat.bool(ctx.seed),
    })
  );

  // Seed tiktok_account_metrics (5 metrics per account)
  await seed.tiktok_account_metrics((x) =>
    x(5, {
      follower_count: (ctx) =>
        copycat.int(ctx.seed, { min: 1000, max: 1000000 }),
      post_count: (ctx) => copycat.int(ctx.seed, { min: 10, max: 1000 }),
      timestamp: (ctx) =>
        copycat.dateString(ctx.seed, { minYear: 2020, maxYear: 2023 }),
    })
  );

  // Seed tiktok_post_db (10 posts per account)
  await seed.tiktok_post_db((x) =>
    x(10, {
      post_caption: (ctx) => copycat.sentence(ctx.seed),
      media_type: "video", // TikTok posts are always videos
      image_url: (ctx) =>
        `https://picsum.photos/1080/1920?random=${copycat.int(ctx.seed, {
          min: 1,
          max: 1000,
        })}`,
      image_url_cdn: (ctx) =>
        `https://picsum.photos/1080/1920?random=${copycat.int(ctx.seed, {
          min: 1,
          max: 1000,
        })}`,
      video_duration: (ctx) => copycat.float(ctx.seed, { min: 1, max: 60 }),
      post_url: (ctx) =>
        `https://tiktok.com/@${copycat.username(ctx.seed)}-${
          ctx.index
        }/video/${copycat.int(ctx.seed, { min: 100000000, max: 999999999 })}`,
      active: (ctx) => copycat.bool(ctx.seed),
    })
  );

  // Seed tiktok_post_metrics (3 metrics per post)
  await seed.tiktok_post_metrics((x) =>
    x(3, {
      like_count: (ctx) => copycat.int(ctx.seed, { min: 0, max: 10000 }),
      comment_count: (ctx) => copycat.int(ctx.seed, { min: 0, max: 1000 }),
      play_count: (ctx) => copycat.int(ctx.seed, { min: 0, max: 100000 }),
      share_count: (ctx) => copycat.int(ctx.seed, { min: 0, max: 1000 }),
      bookmark_count: (ctx) => copycat.int(ctx.seed, { min: 0, max: 500 }),
      timestamp: (ctx) =>
        copycat.dateString(ctx.seed, { minYear: 2020, maxYear: 2023 }),
    })
  );

  // Seed apify_datasets (5 entries)
  await seed.apify_datasets((x) =>
    x(5, {
      function_name: (ctx) => copycat.word(ctx.seed),
      target: (ctx) => copycat.word(ctx.seed),
      dataset_ids: (ctx) => [copycat.uuid(ctx.seed)],
      successful_retrieval: (ctx) => copycat.bool(ctx.seed),
    })
  );

  process.exit();
}

main();
