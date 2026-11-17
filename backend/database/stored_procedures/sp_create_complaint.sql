USE smart_community_db;

DROP PROCEDURE IF EXISTS sp_create_complaint;

DELIMITER $$

CREATE PROCEDURE sp_create_complaint(
    IN p_title VARCHAR(150),
    IN p_category VARCHAR(50),
    IN p_description TEXT,
    IN p_location VARCHAR(255),
    IN p_user_id INT,
    IN p_photo_url VARCHAR(255)
)
BEGIN
    INSERT INTO complaints (
        title,
        category,
        description,
        location,
        user_id,
        photo_url
    )
    VALUES (
        p_title,
        p_category,
        p_description,
        p_location,
        p_user_id,
        p_photo_url
    );

    SELECT LAST_INSERT_ID() AS complaintId;
END$$

DELIMITER ;