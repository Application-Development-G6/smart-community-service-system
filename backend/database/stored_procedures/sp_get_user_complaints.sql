USE smart_community_db;

DROP PROCEDURE IF EXISTS sp_get_user_complaints;

DELIMITER $$

CREATE PROCEDURE sp_get_user_complaints(
    IN p_user_id INT
)
BEGIN
    SELECT
        id,
        user_id,
        title,
        category,
        location,
        description,
        photo_url,
        status,
        admin_remark,
        created_at
    FROM complaints
    WHERE user_id = p_user_id
    ORDER BY created_at DESC, id DESC;
END$$

DELIMITER ;
