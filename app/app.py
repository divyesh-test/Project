from flask import Flask, render_template, request, redirect
import sqlite3
import os
print("Current working directory:", os.getcwd())
DB_FILE = os.path.join(os.path.dirname(__file__), 'users.db')



app = Flask(__name__)

# DB setup (run once)
def init_db():
    conn = sqlite3.connect('users.db')
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT NOT NULL,
            age INTEGER NOT NULL
        )
    ''')
    conn.commit()
    conn.close()

@app.route('/')
def index():
    return render_template('form.html')

@app.route('/submit', methods=['POST'])
def submit():
  try:
    name = request.form['name']
    phone = request.form['phone']
    age = request.form['age']

    conn = sqlite3.connect('users.db')
    cursor = conn.cursor()
    cursor.execute('INSERT INTO users (name, phone, age) VALUES (?, ?, ?)', (name, phone, age))
    conn.commit()
    conn.close()
    return "Data submitted successfully!"
  except Exception as e:
      return f"an error occured {e}"
  
@app.route('/users')
def list_users():
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM users')
    users = cursor.fetchall()
    conn.close()
    return render_template('users.html',users=users)

if __name__ == '__main__':
    init_db()
    app.run(debug=True)
