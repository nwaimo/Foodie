//  SQLiteHelper.swift
//  Foodie
//
//  Created on 2/28/2025.
//

import Foundation
import SQLite3

/// A utility class with static methods to help with common SQLite operations
class SQLiteHelper {
    
    /// Executes a SQL statement that doesn't return any results
    /// - Parameters:
    ///   - db: The database connection
    ///   - sql: The SQL statement to execute
    ///   - parameters: Optional closure to bind parameters to the statement
    /// - Returns: True if successful, false otherwise
    static func execute(db: OpaquePointer?, sql: String, parameters: ((OpaquePointer) -> Void)? = nil) -> Bool {
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("Error preparing statement: \(sql)")
            if let errorMessage = String(validatingUTF8: sqlite3_errmsg(db)) {
                print("SQLite error: \(errorMessage)")
            }
            return false
        }
        
        // Bind parameters if provided
        parameters?(statement!)
        
        let result = sqlite3_step(statement)
        sqlite3_finalize(statement)
        
        return result == SQLITE_DONE
    }
    
    /// Executes a SQL query and processes each row with a handler
    /// - Parameters:
    ///   - db: The database connection
    ///   - sql: The SQL query to execute
    ///   - parameters: Optional closure to bind parameters to the statement
    ///   - rowHandler: Closure to process each row of results
    /// - Returns: True if query executed successfully, false otherwise
    static func query(db: OpaquePointer?, sql: String, parameters: ((OpaquePointer) -> Void)? = nil, rowHandler: (OpaquePointer) -> Void) -> Bool {
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("Error preparing query: \(sql)")
            if let errorMessage = String(validatingUTF8: sqlite3_errmsg(db)) {
                print("SQLite error: \(errorMessage)")
            }
            return false
        }
        
        // Bind parameters if provided
        parameters?(statement!)
        
        // Process each row
        while sqlite3_step(statement) == SQLITE_ROW {
            rowHandler(statement!)
        }
        
        sqlite3_finalize(statement)
        return true
    }
    
    /// Binds a string value to a parameter in a prepared statement
    /// - Parameters:
    ///   - statement: The prepared statement
    ///   - index: The parameter index (1-based)
    ///   - value: The string value to bind
    static func bindString(_ statement: OpaquePointer, index: Int, value: String) {
        sqlite3_bind_text(statement, Int32(index), (value as NSString).utf8String, -1, nil)
    }
    
    /// Binds an integer value to a parameter in a prepared statement
    /// - Parameters:
    ///   - statement: The prepared statement
    ///   - index: The parameter index (1-based)
    ///   - value: The integer value to bind
    static func bindInt(_ statement: OpaquePointer, index: Int, value: Int) {
        sqlite3_bind_int(statement, Int32(index), Int32(value))
    }
    
    /// Binds a double value to a parameter in a prepared statement
    /// - Parameters:
    ///   - statement: The prepared statement
    ///   - index: The parameter index (1-based)
    ///   - value: The double value to bind
    static func bindDouble(_ statement: OpaquePointer, index: Int, value: Double) {
        sqlite3_bind_double(statement, Int32(index), value)
    }
    
    /// Binds a nullable double value to a parameter in a prepared statement
    /// - Parameters:
    ///   - statement: The prepared statement
    ///   - index: The parameter index (1-based)
    ///   - value: The optional double value to bind
    static func bindOptionalDouble(_ statement: OpaquePointer, index: Int, value: Double?) {
        if let value = value {
            sqlite3_bind_double(statement, Int32(index), value)
        } else {
            sqlite3_bind_null(statement, Int32(index))
        }
    }
    
    /// Gets a string value from a column in a result row
    /// - Parameters:
    ///   - statement: The statement with the current result row
    ///   - index: The column index (0-based)
    /// - Returns: The string value or nil if the column is NULL
    static func getString(_ statement: OpaquePointer, index: Int) -> String? {
        guard sqlite3_column_type(statement, Int32(index)) != SQLITE_NULL else {
            return nil
        }
        
        guard let cString = sqlite3_column_text(statement, Int32(index)) else {
            return nil
        }
        
        return String(cString: cString)
    }
    
    /// Gets an integer value from a column in a result row
    /// - Parameters:
    ///   - statement: The statement with the current result row
    ///   - index: The column index (0-based)
    /// - Returns: The integer value
    static func getInt(_ statement: OpaquePointer, index: Int) -> Int {
        return Int(sqlite3_column_int(statement, Int32(index)))
    }
    
    /// Gets a double value from a column in a result row
    /// - Parameters:
    ///   - statement: The statement with the current result row
    ///   - index: The column index (0-based)
    /// - Returns: The double value
    static func getDouble(_ statement: OpaquePointer, index: Int) -> Double {
        return sqlite3_column_double(statement, Int32(index))
    }
    
    /// Gets an optional double value from a column in a result row
    /// - Parameters:
    ///   - statement: The statement with the current result row
    ///   - index: The column index (0-based)
    /// - Returns: The double value or nil if the column is NULL
    static func getOptionalDouble(_ statement: OpaquePointer, index: Int) -> Double? {
        guard sqlite3_column_type(statement, Int32(index)) != SQLITE_NULL else {
            return nil
        }
        
        return sqlite3_column_double(statement, Int32(index))
    }
}
