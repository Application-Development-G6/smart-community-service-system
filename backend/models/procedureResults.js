function findProcedureRow(results, field) {
    if (!Array.isArray(results)) {
        return results &&
            typeof results === 'object' &&
            Object.prototype.hasOwnProperty.call(results, field)
            ? results
            : null;
    }

    for (const result of results) {
        const row = findProcedureRow(result, field);
        if (row) {
            return row;
        }
    }

    return null;
}

function findProcedureRows(results, field) {
    if (!Array.isArray(results)) {
        return null;
    }

    for (const resultSet of results) {
        if (!Array.isArray(resultSet)) {
            continue;
        }

        const rows = resultSet.filter(
            (row) => row &&
                typeof row === 'object' &&
                !Array.isArray(row) &&
                Object.prototype.hasOwnProperty.call(row, field)
        );

        if (rows.length > 0) {
            return rows;
        }
    }

    for (const result of results) {
        const nestedResultSet = findProcedureRows(result, field);
        if (nestedResultSet) {
            return nestedResultSet;
        }
    }

    return results.find(
        (resultSet) => Array.isArray(resultSet) && resultSet.length === 0
    ) || null;
}

module.exports = {
    findProcedureRow,
    findProcedureRows
};
