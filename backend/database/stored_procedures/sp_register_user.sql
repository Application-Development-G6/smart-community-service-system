USE smart_community_db;

DROP PROCEDURE IF EXISTS sp_register_user;

DELIMITER $$

CREATE PROCEDURE sp_register_user(
    IN p_full_name VARCHAR(150),
    IN p_email VARCHAR(255),
    IN p_password_hash VARCHAR(255)
)
BEGIN
    INSERT INTO users (full_name, email, password_hash)
    VALUES (p_full_name, p_email, p_password_hash);

    SELECT id, full_name, email, role
    FROM users
    WHERE id = LAST_INSERT_ID();
END$$

DELIMITER ;
