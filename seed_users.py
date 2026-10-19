"""
Seed script to create initial demo users with werkzeug hashed passwords
and link them to all existing startups.
"""
from werkzeug.security import generate_password_hash
import oracledb
from config import Config


def seed_users():
    print("Connecting to Oracle database to seed users...")
    conn = oracledb.connect(
        user=Config.DB_USER,
        password=Config.DB_PASSWORD,
        dsn=Config.DB_DSN
    )
    cursor = conn.cursor()

    users_data = [
        ("admin", "Flight Administrator", "admin123", "ADMIN"),
        ("accountant", "Chief Financial Controller", "acc123", "ACCOUNTANT"),
        ("viewer", "Auditor & Investor Observer", "view123", "VIEWER"),
    ]

    try:
        # Get all startup IDs
        cursor.execute("SELECT startup_id, name FROM startups ORDER BY startup_id")
        startups = cursor.fetchall()
        print(f"Found {len(startups)} startups: {[s[1] for s in startups]}")

        for username, full_name, password, role in users_data:
            pw_hash = generate_password_hash(password)

            # Check if user already exists
            cursor.execute("SELECT user_id FROM users WHERE username = :username", {"username": username})
            row = cursor.fetchone()

            if row:
                user_id = row[0]
                cursor.execute(
                    """
                    UPDATE users 
                    SET full_name = :full_name, password_hash = :hash, role = :role, is_active = 1
                    WHERE user_id = :user_id
                    """,
                    {"full_name": full_name, "hash": pw_hash, "role": role, "user_id": user_id}
                )
                print(f"Updated user: {username} (ID: {user_id}, Role: {role})")
            else:
                user_id_var = cursor.var(oracledb.NUMBER)
                cursor.execute(
                    """
                    INSERT INTO users (username, full_name, password_hash, role, is_active)
                    VALUES (:username, :full_name, :hash, :role, 1)
                    RETURNING user_id INTO :user_id
                    """,
                    {"username": username, "full_name": full_name, "hash": pw_hash, "role": role, "user_id": user_id_var}
                )
                user_id = user_id_var.getvalue()[0]
                print(f"Created user: {username} (ID: {user_id}, Role: {role})")

            # Grant access to all startups
            for startup_id, s_name in startups:
                cursor.execute(
                    """
                    SELECT COUNT(*) FROM user_startup_access 
                    WHERE user_id = :user_id AND startup_id = :startup_id
                    """,
                    {"user_id": user_id, "startup_id": startup_id}
                )
                if cursor.fetchone()[0] == 0:
                    cursor.execute(
                        """
                        INSERT INTO user_startup_access (user_id, startup_id)
                        VALUES (:user_id, :startup_id)
                        """,
                        {"user_id": user_id, "startup_id": startup_id}
                    )
                    print(f"  -> Granted access to startup: {s_name} (ID: {startup_id})")

        conn.commit()
        print("\nAll users successfully seeded and verified!")

    except Exception as e:
        conn.rollback()
        print(f"Error seeding users: {e}")
        raise
    finally:
        cursor.close()
        conn.close()


if __name__ == "__main__":
    seed_users()
