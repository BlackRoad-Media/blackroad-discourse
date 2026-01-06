# frozen_string_literal: true

class NotificationQuery
  attr_reader :user, :guardian

  def initialize(user:, guardian: nil)
    @user = user
    @guardian = guardian || Guardian.new(user)
  end

  def list(limit: 30, offset: 0, types: nil, filter: nil, order: :desc)
    scope = base_visible_scope
    scope = scope.where(notification_type: types) if types.present?
    scope = scope.where(read: true) if filter == "read"
    scope = scope.where(read: false) if filter == "unread"

    scope =
      if order == :prioritized
        scope.prioritized
      else
        scope.order(created_at: order)
      end

    scope.offset(offset).limit(limit).to_a
  end

  def prioritized_list(limit: 30, types: nil)
    scope = base_visible_scope
    scope = scope.prioritized(types.present? ? [] : Notification.like_types)
    scope = scope.where(notification_type: types) if types.present?

    if types.blank? &&
         @user.user_option&.like_notification_frequency ==
           UserOption.like_notification_frequency_type[:never]
      scope = scope.where.not(notification_type: Notification.like_types)
    end

    scope.limit(limit).to_a
  end

  def unread_count
    base_visible_scope
      .where(read: false)
      .where("notifications.id > ?", @user.seen_notification_id)
      .limit(User.max_unread_notifications)
      .count
  end

  def unread_high_priority_count
    base_visible_scope.where(read: false, high_priority: true).count
  end

  def unread_low_priority_count
    base_visible_scope
      .where(read: false, high_priority: false)
      .where("notifications.id > ?", @user.seen_notification_id)
      .limit(User.max_unread_notifications)
      .count
  end

  def grouped_unread_counts
    base_visible_scope
      .where(read: false)
      .limit(User::MAX_UNREAD_BACKLOG)
      .group(:notification_type)
      .count
  end

  def unread_count_for_type(notification_type, since: nil)
    scope = base_visible_scope.where(read: false, notification_type:)
    scope = scope.where("notifications.created_at > ?", since) if since
    scope.count
  end

  def new_personal_messages_count
    base_visible_scope
      .where(read: false)
      .where("notifications.id > ?", @user.seen_notification_id)
      .where(notification_type: Notification.types[:private_message])
      .count
  end

  def total_count(filter: nil)
    scope = base_visible_scope
    scope = scope.where(read: true) if filter == "read"
    scope = scope.where(read: false) if filter == "unread"
    scope.count
  end

  def recent_ids_with_read_status(limit: 20)
    high_priority_unread =
      base_visible_scope
        .where(read: false, high_priority: true)
        .order(id: :desc)
        .limit(limit)
        .pluck(:id, :read)

    other =
      base_visible_scope
        .where("notifications.high_priority = FALSE OR notifications.read = TRUE")
        .order(id: :desc)
        .limit(limit)
        .pluck(:id, :read)

    high_priority_unread + other
  end

  private

  def base_visible_scope
    @base_visible_scope ||= build_visible_scope
  end

  def build_visible_scope
    # Note: We use manual LEFT JOINs instead of .includes(:topic) to avoid
    # redundant queries. The topic data is already available from the join.
    Notification
      .where(user_id: @user.id)
      .joins("LEFT JOIN topics t ON t.id = notifications.topic_id")
      .joins("LEFT JOIN categories c ON c.id = t.category_id")
      .where(visible_topic_condition)
  end

  # Notification is visible if:
  # 1. It has no topic_id (chat notifications, etc.)
  # 2. OR the topic exists, is not deleted (unless staff), AND user can access it
  def visible_topic_condition
    <<~SQL.squish
      (
        notifications.topic_id IS NULL
        OR (
          t.id IS NOT NULL
          AND #{deleted_topic_condition}
          AND (#{regular_topic_condition} OR #{private_message_condition})
        )
      )
    SQL
  end

  def deleted_topic_condition
    @guardian.is_staff? ? "TRUE" : "t.deleted_at IS NULL"
  end

  def regular_topic_condition
    secure_ids = @user.secure_category_ids

    category_access =
      if secure_ids.empty?
        "c.read_restricted = FALSE"
      else
        "(c.read_restricted = FALSE OR c.id IN (#{secure_ids.join(",")}))"
      end

    "t.archetype = 'regular' AND (c.id IS NULL OR #{category_access})"
  end

  def private_message_condition
    <<~SQL.squish
      t.archetype = 'private_message'
      AND t.id IN (
        SELECT topic_id FROM topic_allowed_users WHERE user_id = #{@user.id}
        UNION
        SELECT tg.topic_id FROM topic_allowed_groups tg
        JOIN group_users gu ON gu.group_id = tg.group_id AND gu.user_id = #{@user.id}
      )
    SQL
  end
end
