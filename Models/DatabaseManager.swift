//  DatabaseManager.swift
//  Foodie
//
//  Created on 2/28/2025.
//

import Foundation
import SQLite3

class DatabaseManager {
    static let shared = DatabaseManager()
    
    private var db: OpaquePointer?
    private let dbPath: String
    
    private init() {
        // Get the path to the documents directory
        let fileURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("foodie.sqlite")
        
        dbPath = fileURL.path
        
        // Open the database
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("Error opening database")
            if let errorMessage = String(validatingUTF8: sqlite3_errmsg(db)) {
                print("SQLite error: \(errorMessage)")
            }
            return
        }
        
        // Enable foreign keys
        SQLiteHelper.execute(db: db, sql: "PRAGMA foreign_keys = ON;")
        
        // Create tables if they don't exist
        createTables()
    }
    
    deinit {
        sqlite3_close(db)
    }
    
    // MARK: - Table Creation
    
    private func createTables() {
        // Create settings table
        let createSettingsTable = """
        CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
        );
        """
        
        // Create consumption table
        let createConsumptionTable = """
        CREATE TABLE IF NOT EXISTS consumption (
            id TEXT PRIMARY KEY,
            category TEXT NOT NULL,
            calories INTEGER NOT NULL,
            timestamp REAL NOT NULL,
            water_amount REAL
        );
        """
        
        // Create index on timestamp for faster queries by date
        let createTimestampIndex = """
        CREATE INDEX IF NOT EXISTS idx_consumption_timestamp
        ON consumption (timestamp);
        """
        
        // Execute the SQL statements
        if SQLiteHelper.execute(db: db, sql: createSettingsTable) && 
           SQLiteHelper.execute(db: db, sql: createConsumptionTable) &&
           SQLiteHelper.execute(db: db, sql: createTimestampIndex) {
            print("Database tables created successfully")
            
            // Insert default settings if they don't exist
            insertDefaultSettings()
        } else {
            print("Error creating tables")
        }
    }
    
    private func insertDefaultSettings() {
        // Check if settings exist
        if getSetting(key: "WaterTarget") == nil {
            setSetting(key: "WaterTarget", value: "2.0")
        }
        
        if getSetting(key: "CalorieTarget") == nil {
            setSetting(key: "CalorieTarget", value: "2000")
        }
    }
    
    // MARK: - Settings Methods
    
    func setSetting(key: String, value: String) {
        let sql = "INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?);"
        
        SQLiteHelper.execute(db: db, sql: sql) { statement in
            SQLiteHelper.bindString(statement, index: 1, value: key)
            SQLiteHelper.bindString(statement, index: 2, value: value)
        }
    }
    
    func getSetting(key: String) -> String? {
        let sql = "SELECT value FROM settings WHERE key = ?;"
        var result: String?
        
        SQLiteHelper.query(db: db, sql: sql, parameters: { statement in
            SQLiteHelper.bindString(statement, index: 1, value: key)
        }) { statement in
            result = SQLiteHelper.getString(statement, index: 0)
        }
        
        return result
    }
    
    // MARK: - Consumption Methods
    
    func saveConsumptionItem(_ item: ConsumptionItem) {
        let sql = """
        INSERT OR REPLACE INTO consumption (id, category, calories, timestamp, water_amount)
        VALUES (?, ?, ?, ?, ?);
        """
        
        SQLiteHelper.execute(db: db, sql: sql) { statement in
            SQLiteHelper.bindString(statement, index: 1, value: item.id.uuidString)
            SQLiteHelper.bindString(statement, index: 2, value: item.category.rawValue)
            SQLiteHelper.bindInt(statement, index: 3, value: item.calories)
            SQLiteHelper.bindDouble(statement, index: 4, value: item.timestamp.timeIntervalSince1970)
            SQLiteHelper.bindOptionalDouble(statement, index: 5, value: item.waterAmount)
        }
    }
    
    func getAllConsumptionItems() -> [ConsumptionItem] {
        var items: [ConsumptionItem] = []
        let sql = "SELECT id, category, calories, timestamp, water_amount FROM consumption ORDER BY timestamp DESC;"
        
        SQLiteHelper.query(db: db, sql: sql) { statement in
            if let idString = SQLiteHelper.getString(statement, index: 0),
               let id = UUID(uuidString: idString),
               let categoryString = SQLiteHelper.getString(statement, index: 1),
               let category = MealCategory(rawValue: categoryString) {
                
                let calories = SQLiteHelper.getInt(statement, index: 2)
                let timestamp = Date(timeIntervalSince1970: SQLiteHelper.getDouble(statement, index: 3))
                let waterAmount = SQLiteHelper.getOptionalDouble(statement, index: 4)
                
                let item = ConsumptionItem(
                    id: id,
                    category: category,
                    calories: calories,
                    timestamp: timestamp,
                    waterAmount: waterAmount
                )
                
                items.append(item)
            }
        }
        
        return items
    }
    
    func getConsumptionItems(forDate date: Date) -> [ConsumptionItem] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let startTimestamp = startOfDay.timeIntervalSince1970
        let endTimestamp = endOfDay.timeIntervalSince1970
        
        var items: [ConsumptionItem] = []
        let sql = """
        SELECT id, category, calories, timestamp, water_amount 
        FROM consumption 
        WHERE timestamp >= ? AND timestamp < ?
        ORDER BY timestamp DESC;
        """
        
        SQLiteHelper.query(db: db, sql: sql, parameters: { statement in
            SQLiteHelper.bindDouble(statement, index: 1, value: startTimestamp)
            SQLiteHelper.bindDouble(statement, index: 2, value: endTimestamp)
        }) { statement in
            if let idString = SQLiteHelper.getString(statement, index: 0),
               let id = UUID(uuidString: idString),
               let categoryString = SQLiteHelper.getString(statement, index: 1),
               let category = MealCategory(rawValue: categoryString) {
                
                let calories = SQLiteHelper.getInt(statement, index: 2)
                let timestamp = Date(timeIntervalSince1970: SQLiteHelper.getDouble(statement, index: 3))
                let waterAmount = SQLiteHelper.getOptionalDouble(statement, index: 4)
                
                let item = ConsumptionItem(
                    id: id,
                    category: category,
                    calories: calories,
                    timestamp: timestamp,
                    waterAmount: waterAmount
                )
                
                items.append(item)
            }
        }
        
        return items
    }
    
    func deleteConsumptionItem(id: UUID) {
        let sql = "DELETE FROM consumption WHERE id = ?;"
        
        SQLiteHelper.execute(db: db, sql: sql) { statement in
            SQLiteHelper.bindString(statement, index: 1, value: id.uuidString)
        }
    }
    
    func clearConsumptionItems(forDate date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let startTimestamp = startOfDay.timeIntervalSince1970
        let endTimestamp = endOfDay.timeIntervalSince1970
        
        let sql = "DELETE FROM consumption WHERE timestamp >= ? AND timestamp < ?;"
        
        SQLiteHelper.execute(db: db, sql: sql) { statement in
            SQLiteHelper.bindDouble(statement, index: 1, value: startTimestamp)
            SQLiteHelper.bindDouble(statement, index: 2, value: endTimestamp)
        }
    }
    
    // MARK: - Database Maintenance
    
    func vacuum() {
        // Optimize database size and performance
        SQLiteHelper.execute(db: db, sql: "VACUUM;")
    }
    
    func getItemCount() -> Int {
        let sql = "SELECT COUNT(*) FROM consumption;"
        var count = 0
        
        SQLiteHelper.query(db: db, sql: sql) { statement in
            count = SQLiteHelper.getInt(statement, index: 0)
        }
        
        return count
    }
}
