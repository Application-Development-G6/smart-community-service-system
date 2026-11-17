USE smart_community_db;

DROP PROCEDURE IF EXISTS sp_update_complaint_status;

DELIMITER $$

CREATE PROCEDURE sp_update_complaint_status(
    IN p_id INT,
    IN p_status VARCHAR(20)
)
BEGIN
    DECLARE v_affected_rows INT DEFAULT 0;

    UPDATE complaints
    SET status = p_status
    WHERE id = p_id;

    SET v_affected_rows = ROW_COUNT();

    SELECT IF(
        v_affected_rows > 0 OR EXISTS (
            SELECT 1
            FROM complaints
            WHERE id = p_id
        ),
        1,
        0
    ) AS found;
END$$

DELIMITER ;