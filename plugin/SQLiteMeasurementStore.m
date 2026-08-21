#import "SQLiteMeasurementStore.h"

#import "ImageContext.h"
#import "MeasurementRecord.h"
#import <errno.h>
#import <fcntl.h>
#import <math.h>
#import <sqlite3.h>
#import <sys/stat.h>
#import <unistd.h>

NSErrorDomain const MedisaleMeasurementPersistenceErrorDomain =
    @"jp.medisale.horos.persistence";

typedef NS_ENUM(NSInteger, MedisalePersistenceErrorCode) {
    MedisalePersistenceErrorUnsafePath = 1,
    MedisalePersistenceErrorInvalidRecord,
    MedisalePersistenceErrorOpen,
    MedisalePersistenceErrorBusy,
    MedisalePersistenceErrorConstraint,
    MedisalePersistenceErrorIO,
    MedisalePersistenceErrorStatement,
    MedisalePersistenceErrorCommit,
    MedisalePersistenceErrorInjected,
};

static NSError *MedisalePersistenceError(MedisalePersistenceErrorCode code,
                                         NSString *description)
{
    return [NSError errorWithDomain:MedisaleMeasurementPersistenceErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: description}];
}

static NSError *MedisaleSQLiteError(int result, NSString *operation)
{
    int primary = result & 0xff;
    MedisalePersistenceErrorCode code = MedisalePersistenceErrorStatement;
    if (primary == SQLITE_BUSY || primary == SQLITE_LOCKED) {
        code = MedisalePersistenceErrorBusy;
    } else if (primary == SQLITE_CONSTRAINT) {
        code = MedisalePersistenceErrorConstraint;
    } else if (primary == SQLITE_IOERR || primary == SQLITE_CANTOPEN ||
               primary == SQLITE_READONLY || primary == SQLITE_FULL ||
               primary == SQLITE_PERM) {
        code = MedisalePersistenceErrorIO;
    }
    return MedisalePersistenceError(code,
        [NSString stringWithFormat:@"The standalone store could not %@.", operation]);
}

static BOOL MedisalePathIsWithinHome(NSString *path)
{
    NSString *home = NSHomeDirectory().stringByStandardizingPath;
    NSString *candidate = path.stringByStandardizingPath;
    return candidate.length > home.length &&
        [candidate hasPrefix:[home stringByAppendingString:@"/"]];
}

static BOOL MedisaleValidateOwnedPathComponent(NSString *path,
                                               BOOL requireDirectory,
                                               NSError **error)
{
    struct stat status;
    if (lstat(path.fileSystemRepresentation, &status) != 0) {
        if (error != NULL) {
            *error = MedisalePersistenceError(MedisalePersistenceErrorUnsafePath,
                @"The standalone store path could not be validated.");
        }
        return NO;
    }
    BOOL correctType = requireDirectory ? S_ISDIR(status.st_mode) : S_ISREG(status.st_mode);
    if (S_ISLNK(status.st_mode) || !correctType || status.st_uid != getuid()) {
        if (error != NULL) {
            *error = MedisalePersistenceError(MedisalePersistenceErrorUnsafePath,
                @"The standalone store path is not an owned regular location.");
        }
        return NO;
    }
    return YES;
}

static BOOL MedisaleValidateNoSymlinkComponents(NSString *path, NSError **error)
{
    NSString *home = NSHomeDirectory().stringByStandardizingPath;
    if (!MedisalePathIsWithinHome(path)) {
        if (error != NULL) {
            *error = MedisalePersistenceError(MedisalePersistenceErrorUnsafePath,
                @"The standalone store must remain inside the current user's home.");
        }
        return NO;
    }
    if (!MedisaleValidateOwnedPathComponent(home, YES, error)) {
        return NO;
    }
    NSString *relative = [path substringFromIndex:home.length + 1];
    NSString *current = home;
    for (NSString *component in relative.pathComponents) {
        current = [current stringByAppendingPathComponent:component];
        if (!MedisaleValidateOwnedPathComponent(current, YES, error)) {
            return NO;
        }
    }
    return YES;
}

static BOOL MedisaleEnsureOwnedDirectory(NSURL *directoryURL, NSError **error)
{
    NSString *path = directoryURL.path.stringByStandardizingPath;
    if (!MedisalePathIsWithinHome(path)) {
        if (error != NULL) {
            *error = MedisalePersistenceError(MedisalePersistenceErrorUnsafePath,
                @"The standalone store directory is outside the current user's home.");
        }
        return NO;
    }
    NSString *home = NSHomeDirectory().stringByStandardizingPath;
    if (!MedisaleValidateOwnedPathComponent(home, YES, error)) {
        return NO;
    }
    NSString *relative = [path substringFromIndex:home.length + 1];
    NSString *current = home;
    for (NSString *component in relative.pathComponents) {
        current = [current stringByAppendingPathComponent:component];
        struct stat componentStatus;
        if (lstat(current.fileSystemRepresentation, &componentStatus) != 0) {
            if (errno != ENOENT || mkdir(current.fileSystemRepresentation, 0700) != 0) {
                if (error != NULL) {
                    *error = MedisalePersistenceError(MedisalePersistenceErrorIO,
                        @"The standalone store directory could not be created safely.");
                }
                return NO;
            }
        }
        if (!MedisaleValidateOwnedPathComponent(current, YES, error)) {
            return NO;
        }
    }
    struct stat status;
    if (lstat(path.fileSystemRepresentation, &status) != 0 ||
        (status.st_mode & 0077) != 0) {
        if (error != NULL) {
            *error = MedisalePersistenceError(MedisalePersistenceErrorUnsafePath,
                @"The standalone store directory permissions are not restrictive.");
        }
        return NO;
    }
    return YES;
}

static BOOL MedisaleEnsureOwnedDatabaseFile(NSURL *databaseURL, NSError **error)
{
    NSString *path = databaseURL.path.stringByStandardizingPath;
    struct stat status;
    if (lstat(path.fileSystemRepresentation, &status) != 0) {
        if (errno != ENOENT) {
            if (error != NULL) {
                *error = MedisalePersistenceError(MedisalePersistenceErrorUnsafePath,
                    @"The standalone database file could not be inspected.");
            }
            return NO;
        }
        int descriptor = open(path.fileSystemRepresentation,
                              O_CREAT | O_EXCL | O_RDWR | O_NOFOLLOW,
                              S_IRUSR | S_IWUSR);
        if (descriptor < 0) {
            if (error != NULL) {
                *error = MedisalePersistenceError(MedisalePersistenceErrorIO,
                    @"The standalone database file could not be created safely.");
            }
            return NO;
        }
        close(descriptor);
    }
    if (!MedisaleValidateOwnedPathComponent(path, NO, error)) {
        return NO;
    }
    if (lstat(path.fileSystemRepresentation, &status) != 0 ||
        (status.st_mode & 0077) != 0) {
        if (error != NULL) {
            *error = MedisalePersistenceError(MedisalePersistenceErrorUnsafePath,
                @"The standalone database permissions are not restrictive.");
        }
        return NO;
    }
    char canonicalDatabase[PATH_MAX];
    char canonicalHome[PATH_MAX];
    if (realpath(path.fileSystemRepresentation, canonicalDatabase) == NULL ||
        realpath(NSHomeDirectory().fileSystemRepresentation, canonicalHome) == NULL) {
        if (error != NULL) {
            *error = MedisalePersistenceError(MedisalePersistenceErrorUnsafePath,
                @"The standalone database canonical path could not be verified.");
        }
        return NO;
    }
    NSString *resolvedDatabase = [NSString stringWithUTF8String:canonicalDatabase];
    NSString *resolvedHome = [NSString stringWithUTF8String:canonicalHome];
    BOOL contained = resolvedDatabase.length > resolvedHome.length &&
        [resolvedDatabase hasPrefix:[resolvedHome stringByAppendingString:@"/"]];
    if (!contained && error != NULL) {
        *error = MedisalePersistenceError(MedisalePersistenceErrorUnsafePath,
            @"The standalone database canonical path is not contained in the user home.");
    }
    return contained;
}

static BOOL MedisaleRecordIsValid(MeasurementRecord *record)
{
    ImageContext *context = record.imageContext;
    return record.measurementID.length > 0 &&
        context.studyInstanceUID.length > 0 &&
        context.seriesInstanceUID.length > 0 &&
        context.sopInstanceUID.length > 0 &&
        context.frameNumber >= 0 &&
        isfinite(record.endpointAX) && isfinite(record.endpointAY) &&
        isfinite(record.endpointBX) && isfinite(record.endpointBY) &&
        isfinite(record.pixelDistance) && record.pixelDistance >= 0.0 &&
        record.schemaVersion == MedisaleMeasurementSchemaVersion &&
        record.createdAt != nil && record.updatedAt != nil &&
        [record.updatedAt compare:record.createdAt] != NSOrderedAscending;
}

@interface SQLiteMeasurementStore ()
@property(nonatomic, readwrite) NSURL *databaseURL;
@end

@implementation SQLiteMeasurementStore

+ (instancetype)pluginOwnedStoreWithError:(NSError **)error
{
    NSURL *home = [NSURL fileURLWithPath:NSHomeDirectory() isDirectory:YES];
    NSURL *directory = [[[[home URLByAppendingPathComponent:@"Library" isDirectory:YES]
        URLByAppendingPathComponent:@"Application Support" isDirectory:YES]
        URLByAppendingPathComponent:@"Medisale Horos Suite" isDirectory:YES]
        URLByAppendingPathComponent:@"Spike P1-11" isDirectory:YES];
    NSURL *database = [directory URLByAppendingPathComponent:@"measurements.sqlite3"
                                                 isDirectory:NO];
    return [[self alloc] initWithDatabaseURL:database error:error];
}

- (instancetype)initWithDatabaseURL:(NSURL *)databaseURL error:(NSError **)error
{
    self = [super init];
    if (self) {
        NSURL *standardized = databaseURL.standardizedURL;
        if (!standardized.isFileURL || standardized.lastPathComponent.length == 0 ||
            !MedisalePathIsWithinHome(standardized.path)) {
            if (error != NULL) {
                *error = MedisalePersistenceError(MedisalePersistenceErrorUnsafePath,
                    @"The standalone database location is not allowed.");
            }
            return nil;
        }
        NSURL *parent = [standardized URLByDeletingLastPathComponent];
        if (!MedisaleEnsureOwnedDirectory(parent, error) ||
            !MedisaleEnsureOwnedDatabaseFile(standardized, error)) {
            return nil;
        }
        _databaseURL = standardized;
        if (![self initializeSchema:error]) {
            return nil;
        }
    }
    return self;
}

- (BOOL)openDatabase:(sqlite3 **)database error:(NSError **)error
{
    if (!MedisaleValidateNoSymlinkComponents(
            self.databaseURL.URLByDeletingLastPathComponent.path, error) ||
        !MedisaleEnsureOwnedDatabaseFile(self.databaseURL, error)) {
        return NO;
    }
    sqlite3 *connection = NULL;
    int result = sqlite3_open_v2(self.databaseURL.fileSystemRepresentation,
        &connection, SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX |
        SQLITE_OPEN_NOFOLLOW, NULL);
    if (result != SQLITE_OK) {
        if (connection != NULL) {
            sqlite3_close(connection);
        }
        if (error != NULL) {
            *error = MedisaleSQLiteError(result, @"open its database");
        }
        return NO;
    }
    sqlite3_extended_result_codes(connection, 1);
    sqlite3_busy_timeout(connection, 150);
    char *message = NULL;
    result = sqlite3_exec(connection, "PRAGMA foreign_keys = ON", NULL, NULL, &message);
    sqlite3_free(message);
    if (result != SQLITE_OK) {
        sqlite3_close(connection);
        if (error != NULL) {
            *error = MedisaleSQLiteError(result, @"enable referential integrity");
        }
        return NO;
    }
    *database = connection;
    return YES;
}

- (BOOL)initializeSchema:(NSError **)error
{
    sqlite3 *database = NULL;
    if (![self openDatabase:&database error:error]) {
        return NO;
    }
    static const char *schema =
        "BEGIN IMMEDIATE;"
        "CREATE TABLE IF NOT EXISTS measurements ("
        "measurement_id TEXT PRIMARY KEY NOT NULL CHECK(length(measurement_id) > 0),"
        "study_instance_uid TEXT NOT NULL CHECK(length(study_instance_uid) > 0),"
        "series_instance_uid TEXT NOT NULL CHECK(length(series_instance_uid) > 0),"
        "sop_instance_uid TEXT NOT NULL CHECK(length(sop_instance_uid) > 0),"
        "frame_number INTEGER NOT NULL CHECK(frame_number >= 0),"
        "endpoint_a_x REAL NOT NULL, endpoint_a_y REAL NOT NULL,"
        "endpoint_b_x REAL NOT NULL, endpoint_b_y REAL NOT NULL,"
        "pixel_distance REAL NOT NULL CHECK(pixel_distance >= 0),"
        "schema_version INTEGER NOT NULL CHECK(schema_version = 1),"
        "created_at REAL NOT NULL, updated_at REAL NOT NULL"
        ");"
        "PRAGMA user_version = 1;"
        "COMMIT;";
    char *message = NULL;
    int result = sqlite3_exec(database, schema, NULL, NULL, &message);
    sqlite3_free(message);
    if (result != SQLITE_OK) {
        sqlite3_exec(database, "ROLLBACK", NULL, NULL, NULL);
        if (error != NULL) {
            *error = MedisaleSQLiteError(result, @"initialize its schema");
        }
    }
    sqlite3_close(database);
    return result == SQLITE_OK;
}

- (BOOL)saveMeasurement:(MeasurementRecord *)measurement error:(NSError **)error
{
    if (!MedisaleRecordIsValid(measurement)) {
        if (error != NULL) {
            *error = MedisalePersistenceError(MedisalePersistenceErrorInvalidRecord,
                @"The measurement is incomplete or invalid.");
        }
        return NO;
    }

    sqlite3 *database = NULL;
    sqlite3_stmt *statement = NULL;
    ImageContext *context = measurement.imageContext;
    BOOL transactionStarted = NO;
    BOOL success = NO;
    if (![self openDatabase:&database error:error]) {
        return NO;
    }

    int result = sqlite3_exec(database, "BEGIN IMMEDIATE", NULL, NULL, NULL);
    if (result != SQLITE_OK) {
        if (error != NULL) {
            *error = MedisaleSQLiteError(result, @"begin a transaction");
        }
        goto cleanup;
    }
    transactionStarted = YES;

    if (self.failureInjection == MedisaleSQLiteFailureInjectionConstraint) {
        result = sqlite3_prepare_v2(database,
            "INSERT INTO measurements (measurement_id) VALUES (?)", -1,
            &statement, NULL);
        if (result == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, measurement.measurementID.UTF8String,
                              -1, SQLITE_TRANSIENT);
            result = sqlite3_step(statement);
        }
        if (error != NULL) {
            *error = MedisaleSQLiteError(result, @"satisfy a record constraint");
        }
        goto cleanup;
    }

    if (self.failureInjection == MedisaleSQLiteFailureInjectionStatement) {
        result = sqlite3_prepare_v2(database,
            "INSERT INTO unavailable_spike_table (value) VALUES (?)", -1,
            &statement, NULL);
        if (error != NULL) {
            *error = MedisaleSQLiteError(result, @"prepare a record statement");
        }
        goto cleanup;
    }

    static const char *upsert =
        "INSERT INTO measurements ("
        "measurement_id, study_instance_uid, series_instance_uid, sop_instance_uid,"
        "frame_number, endpoint_a_x, endpoint_a_y, endpoint_b_x, endpoint_b_y,"
        "pixel_distance, schema_version, created_at, updated_at"
        ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) "
        "ON CONFLICT(measurement_id) DO UPDATE SET "
        "study_instance_uid=excluded.study_instance_uid,"
        "series_instance_uid=excluded.series_instance_uid,"
        "sop_instance_uid=excluded.sop_instance_uid,"
        "frame_number=excluded.frame_number,"
        "endpoint_a_x=excluded.endpoint_a_x, endpoint_a_y=excluded.endpoint_a_y,"
        "endpoint_b_x=excluded.endpoint_b_x, endpoint_b_y=excluded.endpoint_b_y,"
        "pixel_distance=excluded.pixel_distance, schema_version=excluded.schema_version,"
        "updated_at=excluded.updated_at";
    result = sqlite3_prepare_v2(database, upsert, -1, &statement, NULL);
    if (result != SQLITE_OK) {
        if (error != NULL) {
            *error = MedisaleSQLiteError(result, @"prepare a save statement");
        }
        goto cleanup;
    }

    sqlite3_bind_text(statement, 1, measurement.measurementID.UTF8String, -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, 2, context.studyInstanceUID.UTF8String, -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, 3, context.seriesInstanceUID.UTF8String, -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, 4, context.sopInstanceUID.UTF8String, -1, SQLITE_TRANSIENT);
    sqlite3_bind_int64(statement, 5, (sqlite3_int64)context.frameNumber);
    sqlite3_bind_double(statement, 6, measurement.endpointAX);
    sqlite3_bind_double(statement, 7, measurement.endpointAY);
    sqlite3_bind_double(statement, 8, measurement.endpointBX);
    sqlite3_bind_double(statement, 9, measurement.endpointBY);
    sqlite3_bind_double(statement, 10, measurement.pixelDistance);
    sqlite3_bind_int64(statement, 11, (sqlite3_int64)measurement.schemaVersion);
    sqlite3_bind_double(statement, 12, measurement.createdAt.timeIntervalSince1970);
    sqlite3_bind_double(statement, 13, measurement.updatedAt.timeIntervalSince1970);
    result = sqlite3_step(statement);
    if (result != SQLITE_DONE) {
        if (error != NULL) {
            *error = MedisaleSQLiteError(result, @"write a record");
        }
        goto cleanup;
    }
    sqlite3_finalize(statement);
    statement = NULL;

    if (self.failureInjection == MedisaleSQLiteFailureInjectionBeforeCommit) {
        if (error != NULL) {
            *error = MedisalePersistenceError(MedisalePersistenceErrorInjected,
                @"The simulated pre-commit operation failed.");
        }
        goto cleanup;
    }
    if (self.failureInjection == MedisaleSQLiteFailureInjectionInterruptedSave) {
        sqlite3_close(database);
        database = NULL;
        transactionStarted = NO;
        if (error != NULL) {
            *error = MedisalePersistenceError(MedisalePersistenceErrorInjected,
                @"The simulated save was interrupted before commit.");
        }
        return NO;
    }

    result = sqlite3_exec(database, "COMMIT", NULL, NULL, NULL);
    if (result != SQLITE_OK) {
        if (error != NULL) {
            *error = MedisaleSQLiteError(result, @"commit a transaction");
        }
        goto cleanup;
    }
    transactionStarted = NO;
    success = YES;

cleanup:
    if (statement != NULL) {
        sqlite3_finalize(statement);
    }
    if (transactionStarted && database != NULL) {
        sqlite3_exec(database, "ROLLBACK", NULL, NULL, NULL);
    }
    if (database != NULL) {
        sqlite3_close(database);
    }
    return success;
}

@end
