import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../Model/income.dart';
import '../Model/price.dart';
import '../Model/stay.dart';

const _dbVersion = 1;

///Class for Database
class DatabaseStay {
  ///Database init
  DatabaseStay();

  ///Variable for database
  late Database db;

  ///Function that init the database
  Future<void> init() async {
    final databasePath = await getDatabasesPath();
    final path = '$databasePath/database2.db';

    db = await openDatabase(path, version: _dbVersion,
        onCreate: (database, version) async {
          await database.execute('''CREATE TABLE Car(
          ID INTEGER NOT NULL,
          ENTRY_DATE TEXT,
          EXIT_DATE	TEXT,
          LICENSE_PLATE	TEXT NOT NULL UNIQUE,
          DRIVER_NAME	TEXT NOT NULL,
          TOTAL_PRICE REAL,
          PRIMARY KEY(ID AUTOINCREMENT));''');
          await database.execute('''CREATE TABLE Precos(
          PARKING_LANE TEXT,
          PRICE REAL,
          INITIAL_RANGE INTEGER,
          END_RANGE INTEGER);''');
        });
  }

  ///Function that insert initial datas in table price
  Future<void> insertPrice(List<Price> list) async {
    for (final price in list) {
      await db.insert('Precos', {
        'PARKING_LANE': price.parkingLane,
        'PRICE': price.priceP,
        'INITIAL_RANGE': price.initialRange,
        'END_RANGE': price.endRange,
      });
    }
  }

  ///Function that insert initial datas in table car
  Future<void> insertIn(Stay stay) async {
    await db.insert('Car', {
      'ENTRY_DATE': stay.entrydate.toString(),
      'LICENSE_PLATE': stay.licenseplate,
      'DRIVER_NAME': stay.drivername,
    });
  }

  ///Function that insert final datas in database
  Future<void> insertOut(DateTime exit, String plate) async {

    await db.update(
      'Car',
      {
        'EXIT_DATE': exit.toString(),
      },
      where: 'LICENSE_PLATE = ?',
      whereArgs: [plate],
    );
  }

  ///Function that insert final total price in database
  Future<void> insertTotalPrice(double price, String plate) async {

    await db.update(
      'Car',
      {
        'TOTAL_PRICE': price,
      },
      where: 'LICENSE_PLATE = ?',
      whereArgs: [plate],
    );
  }

  ///Function to get the Income per day
  Future<List<Income>> getIncomeBd() async {

    final rows = await db.query('Car',
        columns: [
          'EXIT_DATE',
          'sum(TOTAL_PRICE)',
        ],
        groupBy: "strftime('%d-%m-%Y',EXIT_DATE)");

    final list = <Income>[];

    for (final row in rows) {
      list.add(Income.fromDatabaseRowOut(row));
    }

    return list;
  }

  ///Function that get all finished row in database
  Future<List<Stay>> getAllFinished() async {
    final rows = await db.query(
      'Car',
      columns: [
        'ID',
        'ENTRY_DATE',
        'EXIT_DATE',
        'LICENSE_PLATE',
        'DRIVER_NAME',
        'TOTAL_PRICE'
      ],
      orderBy: 'EXIT_DATE ASC',
    );

    final list = <Stay>[];
    for (final row in rows) {
      list.add(Stay.fromDatabaseRowOut(row));
    }

    return list;
  }

  ///Function that delete a row in database
  Future<void> delete(List<Stay> list) async {
    for (final stay in list) {
      await db.delete(
        'Car',
        where: 'LICENSE_PLATE = ?',
        whereArgs: [stay.licenseplate],
      );
    }
  }


  ///Function to get the prices of database
  Future<List<Price>> getPrices() async {
    final rows = await db.query('Precos', columns: [
      'PARKING_LANE',
      'PRICE',
      'INITIAL_RANGE',
      'END_RANGE',
    ]);

    final list = <Price>[];
    for (final row in rows) {
      list.add(Price.fromDatabaseRowOut(row));
    }

    return list;
  }
}
