// Invite a user to the platform
export async function inviteUser(supabase, data) {
  const { email } = data;
  if (!email) {
    throw new Error("Email is required");
  }

  // Send invitation email
  const { data: inviteData, error: inviteError } =
    await supabase.auth.admin.inviteUserByEmail(email);
  if (inviteError) {
    throw inviteError;
  }

  // Update the invited user's app_metadata to set role to 'user'
  const invitedUserId = inviteData.user.id;
  const { error: updateError } = await supabase.auth.admin.updateUserById(
    invitedUserId,
    {
      app_metadata: { role: "user" },
    }
  );
  if (updateError) {
    throw updateError;
  }

  return {
    message: "Invitation sent successfully and user role set to user",
    user: inviteData.user,
  };
}

// Delete a user from the platform
export async function deleteUser(supabase, data) {
  const { user_id } = data;
  if (!user_id) {
    throw new Error("User ID is required");
  }
  const { error } = await supabase.auth.admin.deleteUser(user_id);
  if (error) {
    throw error;
  }
  return { message: "User deleted successfully" };
}

// List all users on the platform
export async function listUsers(supabase) {
  const { data: users, error } = await supabase.auth.admin.listUsers();
  if (error) {
    throw error;
  }
  const enrichedUsers = users.users.map((user) => ({
    id: user.id,
    email: user.email,
    first_name: user.user_metadata?.first_name || null,
    last_name: user.user_metadata?.last_name || null,
    role: user.app_metadata?.role || null,
    last_sign_in_at: user.last_sign_in_at,
    created_at: user.created_at,
  }));
  return { data: enrichedUsers };
}

// Get user details by their ID
export async function getUser(supabase, data) {
  const { user_id } = data;
  if (!user_id) {
    throw new Error("User ID is required");
  }
  const { data: user, error } = await supabase.auth.admin.getUserById(user_id);
  if (error) {
    throw error;
  }
  return {
    data: {
      id: user.user.id,
      email: user.user.email,
      first_name: user.user.user_metadata?.first_name || null,
      last_name: user.user.user_metadata?.last_name || null,
      role: user.user.app_metadata?.role || null,
      last_sign_in_at: user.user.last_sign_in_at,
      created_at: user.user.created_at,
    },
  };
}

// Update a user's name
export async function updateUserName(supabase, data) {
  const { user_id, first_name, last_name } = data;
  if (!user_id || (!first_name && !last_name)) {
    throw new Error(
      "User ID and at least one name field (first_name or last_name) are required"
    );
  }
  const { data: currentUser, error: fetchError } =
    await supabase.auth.admin.getUserById(user_id);
  if (fetchError) {
    throw fetchError;
  }
  const { error } = await supabase.auth.admin.updateUserById(user_id, {
    user_metadata: {
      ...currentUser.user?.user_metadata,
      first_name: first_name || currentUser.user?.user_metadata?.first_name,
      last_name: last_name || currentUser.user?.user_metadata?.last_name,
    },
  });
  if (error) {
    throw error;
  }
  return { message: "User names updated successfully" };
}

// Update a user's role
export async function updateUserRole(supabase, data) {
  const { user_id, role } = data;
  if (!user_id || !role || !["admin", "user"].includes(role)) {
    throw new Error("Valid user ID and role (admin/user) are required");
  }
  const { data: currentUser, error: fetchError } =
    await supabase.auth.admin.getUserById(user_id);
  if (fetchError) {
    throw fetchError;
  }
  const { error } = await supabase.auth.admin.updateUserById(user_id, {
    app_metadata: {
      ...currentUser.user?.app_metadata,
      role,
    },
  });
  if (error) {
    throw error;
  }
  return { message: "User role updated successfully" };
}

// Export all actions
export const actions = {
  invite_user: inviteUser,
  delete_user: deleteUser,
  list_users: listUsers,
  get_user: getUser,
  update_user_name: updateUserName,
  update_user_role: updateUserRole,
};
