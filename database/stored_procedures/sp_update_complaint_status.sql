USE smart_community_db;

DROP PROCEDURE IF EXISTS sp_update_complaint_status;

DELIMITER $$

CREATE PROCEDURE sp_update_complaint_status(
    IN p_id INT,
    IN p_status VARCHAR(20)
)
BEGIN
    UPDATE complaints
    SET status = p_status
    WHERE id = p_id;
END$$

DELIMITER ;