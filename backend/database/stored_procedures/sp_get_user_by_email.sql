USE smart_community_db;

DROP PROCEDURE IF EXISTS sp_get_user_by_email;

DELIMITER $$

CREATE PROCEDURE sp_get_user_by_email(
    IN p_email VARCHAR(255)
)
BEGIN
    SELECT id, full_name, email, password_hash, role
    FROM users
    WHERE email = p_email
    LIMIT 1;
END$$

DELIMITER ;
