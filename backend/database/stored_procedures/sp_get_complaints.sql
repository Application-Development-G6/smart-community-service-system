USE smart_community_db;

DROP PROCEDURE IF EXISTS sp_get_complaints;

DELIMITER $$

CREATE PROCEDURE sp_get_complaints()
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
        created_at
    FROM complaints
    ORDER BY created_at DESC, id DESC;
END$$

DELIMITER ;