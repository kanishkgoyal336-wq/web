/*  ======================================================================
       LIBRARY MANAGEMENT SYSTEM  -  OOPs Project in C++
       Student : Kanishk Goel              UID : 25BCD10117
       Course  : BCA (Hons) Data Science, 3rd Semester
    ======================================================================
    OOP concepts used in this project:
      Classes & Objects, Encapsulation, Constructors (default,
      parameterized, copy), Destructor, Static members, Inline function,
      Default arguments, Function overloading, Operator overloading,
      Friend functions, Inheritance (multilevel + hierarchical),
      Abstract class, Virtual functions (runtime polymorphism),
      Function template, Exception handling, File handling, STL vector
    ====================================================================== */
#include <iostream>
#include <fstream>
#include <sstream>
#include <iomanip>
#include <string>
#include <vector>
#include <limits>
#include <cctype>
using namespace std;

const int LOAN_DAYS = 14;                 // free borrowing period (days)

// ---------------- Inline function with default arguments ----------------
inline void line(char ch = '-', int width = 70) {
    cout << string(width, ch) << "\n";
}

// ---------------- User-defined exception class ----------------
class LibraryException {
    string message;
public:
    LibraryException(const string& msg) : message(msg) {}
    string what() const { return message; }
};

// ======================================================================
//  class Date : stores a date and finds the days between two dates
// ======================================================================
class Date {
    int day, month, year;

    static bool isLeap(int y) {                          // static member function
        return (y % 4 == 0 && y % 100 != 0) || (y % 400 == 0);
    }
    static int daysInMonth(int m, int y) {
        const int dm[12] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
        return (m == 2 && isLeap(y)) ? 29 : dm[m - 1];
    }
    long totalDays() const {                             // days counted from year 1
        long y = year - 1;
        long days = y * 365 + y / 4 - y / 100 + y / 400;
        for (int m = 1; m < month; m++) days += daysInMonth(m, year);
        return days + day;
    }
public:
    Date(int d = 1, int m = 1, int y = 2026) : day(d), month(m), year(y) {}

    int getDay() const   { return day; }
    int getMonth() const { return month; }
    int getYear() const  { return year; }

    bool isValid() const {
        return year >= 2000 && year <= 2100 && month >= 1 && month <= 12
               && day >= 1 && day <= daysInMonth(month, year);
    }
    // Operator overloading : (returnDate - issueDate) gives number of days
    int operator-(const Date& other) const {
        return (int)(totalDays() - other.totalDays());
    }
    // Friend functions : overloading << and >> for Date objects
    friend ostream& operator<<(ostream& out, const Date& d) {
        out << right << setfill('0') << setw(2) << d.day << "/" << setw(2)
            << d.month << "/" << d.year << setfill(' ');
        return out;
    }
    friend istream& operator>>(istream& in, Date& d) {
        in >> d.day >> d.month >> d.year;
        return in;
    }
};

// ======================================================================
//  class Person : ABSTRACT base class (has pure virtual functions)
// ======================================================================
class Person {
protected:
    int id;
    string name;
public:
    Person(int i, const string& n) : id(i), name(n) {}
    virtual ~Person() {}                         // virtual destructor
    int getId() const      { return id; }
    string getName() const { return name; }
    virtual string role() const = 0;             // pure virtual functions
    virtual void display() const = 0;
};

// ======================================================================
//  class Member : derived from Person (still abstract)
// ======================================================================
class Member : public Person {
protected:
    int booksIssued;
public:
    Member(int i, const string& n, int issued = 0)
        : Person(i, n), booksIssued(issued) {}
    int getBooksIssued() const { return booksIssued; }
    void issueOne()  { booksIssued++; }
    void returnOne() { if (booksIssued > 0) booksIssued--; }

    virtual int maxBooks() const = 0;            // different for Student / Faculty
    virtual double finePerDay() const = 0;
    virtual string detail() const = 0;           // course or department

    void display() const override {
        cout << left << setw(6) << id << setw(22) << name << setw(10) << role()
             << setw(18) << detail() << booksIssued << " / " << maxBooks() << "\n";
    }
};

// ---------- Student : Person -> Member -> Student (multilevel) ----------
class Student : public Member {
    string course;
public:
    Student(int i, const string& n, const string& c, int issued = 0)
        : Member(i, n, issued), course(c) {}
    string role() const override       { return "Student"; }
    string detail() const override     { return course; }
    int maxBooks() const override      { return 3; }
    double finePerDay() const override { return 5.0; }
};

// ---------- Faculty : Member -> Faculty (hierarchical) ----------
class Faculty : public Member {
    string department;
public:
    Faculty(int i, const string& n, const string& d, int issued = 0)
        : Member(i, n, issued), department(d) {}
    string role() const override       { return "Faculty"; }
    string detail() const override     { return department; }
    int maxBooks() const override      { return 5; }
    double finePerDay() const override { return 2.0; }
};

// ======================================================================
//  class Book
// ======================================================================
class Book {
    int id;
    string title, author;
    int issuedTo;                    // member ID (0 means book is available)
    Date issueDate;
    static int nextId;               // static data member shared by all books
public:
    // default constructor
    Book() : id(0), issuedTo(0) {}

    // parameterized constructor (new book gets the next automatic ID)
    Book(const string& t, const string& a)
        : id(nextId++), title(t), author(a), issuedTo(0) {}

    // parameterized constructor used while loading records from file
    Book(int i, const string& t, const string& a, int to, const Date& d)
        : id(i), title(t), author(a), issuedTo(to), issueDate(d) {
        if (i >= nextId) nextId = i + 1;
    }

    // copy constructor
    Book(const Book& b)
        : id(b.id), title(b.title), author(b.author),
          issuedTo(b.issuedTo), issueDate(b.issueDate) {}

    int getId() const         { return id; }
    string getTitle() const   { return title; }
    string getAuthor() const  { return author; }
    int getIssuedTo() const   { return issuedTo; }
    Date getIssueDate() const { return issueDate; }
    bool isIssued() const     { return issuedTo != 0; }

    void issue(int memberId, const Date& d) { issuedTo = memberId; issueDate = d; }
    void markReturned()                     { issuedTo = 0; }

    // operator overloading : compare a book with an ID
    bool operator==(int bookId) const { return id == bookId; }

    // friend function : overloading << to print one book row
    friend ostream& operator<<(ostream& out, const Book& b) {
        out << left << setw(6) << b.id << setw(33) << b.title.substr(0, 32)
            << setw(21) << b.author.substr(0, 20)
            << (b.isIssued() ? "Issued" : "Available") << "\n";
        return out;
    }
};
int Book::nextId = 1001;             // definition of static data member

// ---------------- Overloaded helper functions ----------------
int keyOf(const Book& b)     { return b.getId(); }
int keyOf(const Member* m)   { return m->getId(); }

// ---------------- Function template : works for Books and Members ----------------
template <typename T>
int findIndex(const vector<T>& list, int id) {
    for (size_t i = 0; i < list.size(); i++)
        if (keyOf(list[i]) == id) return (int)i;
    return -1;
}

string toLower(string s) {
    for (char& c : s) c = (char)tolower((unsigned char)c);
    return s;
}

// ---------------- Safe input functions ----------------
int readInt(const string& prompt) {
    int x;
    cout << prompt;
    while (!(cin >> x)) {
        if (cin.eof()) return 0;                 // end of input -> exit
        cin.clear();
        cin.ignore(numeric_limits<streamsize>::max(), '\n');
        cout << "  Please enter a valid number: ";
    }
    cin.ignore(numeric_limits<streamsize>::max(), '\n');
    return x;
}

string readText(const string& prompt) {
    string s;
    cout << prompt;
    getline(cin, s);
    if (s.empty()) throw LibraryException("Input cannot be empty.");
    for (char& c : s) if (c == '|') c = '/';     // '|' is used as separator in files
    return s;
}

Date readDate(const string& prompt) {
    Date d;
    cout << prompt;
    cin >> d;                                    // overloaded >> operator
    if (cin.fail()) {
        cin.clear();
        cin.ignore(numeric_limits<streamsize>::max(), '\n');
        throw LibraryException("Date must be entered as: dd mm yyyy");
    }
    cin.ignore(numeric_limits<streamsize>::max(), '\n');
    if (!d.isValid()) throw LibraryException("Invalid date entered.");
    return d;
}

// ======================================================================
//  class Library : manages all books and members
// ======================================================================
class Library {
    vector<Book> books;
    vector<Member*> members;         // base-class pointers -> runtime polymorphism
    int nextMemberId;

    void loadSampleData();
    void bookHeader() const;
public:
    Library();
    ~Library();
    void addBook();
    void showBooks() const;
    void searchBook(int id) const;               // function overloading
    void searchBook(const string& word) const;   // (same name, different parameter)
    void addMember();
    void showMembers() const;
    void issueBook();
    void returnBook();
    void report() const;
    void saveData() const;
};

// ---------- Constructor : loads data from files ----------
Library::Library() : nextMemberId(101) {
    ifstream bf("books.txt"), mf("members.txt");
    if (!bf || !mf) {
        loadSampleData();
    } else {
        string row;
        while (getline(bf, row)) {
            stringstream ss(row);
            string f[7];
            for (int i = 0; i < 7; i++) getline(ss, f[i], '|');
            try {
                books.push_back(Book(stoi(f[0]), f[1], f[2], stoi(f[3]),
                                     Date(stoi(f[4]), stoi(f[5]), stoi(f[6]))));
            } catch (...) { }                        // skip a damaged line
        }
        while (getline(mf, row)) {
            stringstream ss(row);
            string f[5];
            for (int i = 0; i < 5; i++) getline(ss, f[i], '|');
            try {
                int id = stoi(f[1]);
                int issued = stoi(f[4]);
                if (f[0] == "S") members.push_back(new Student(id, f[2], f[3], issued));
                else             members.push_back(new Faculty(id, f[2], f[3], issued));
                if (id >= nextMemberId) nextMemberId = id + 1;
            } catch (...) { }
        }
    }
    cout << "  [INFO] " << books.size() << " books and " << members.size()
         << " members loaded.\n";
}

// ---------- Destructor : frees dynamically allocated members ----------
Library::~Library() {
    for (Member* m : members) delete m;
    cout << "  [INFO] Memory released by destructor. Goodbye!\n";
}

void Library::loadSampleData() {
    books.push_back(Book("Object Oriented Prog. with C++", "E. Balagurusamy"));
    books.push_back(Book("The C++ Programming Language", "Bjarne Stroustrup"));
    books.push_back(Book("Let Us C++", "Yashavant Kanetkar"));
    books.push_back(Book("Data Structures Using C++", "D. S. Malik"));
    books.push_back(Book("Introduction to Algorithms", "T. H. Cormen"));
    books.push_back(Book("Python for Data Analysis", "Wes McKinney"));
    members.push_back(new Student(nextMemberId++, "Rahul Sharma", "BCA-DS"));
    members.push_back(new Faculty(nextMemberId++, "Dr. Anita Mehra", "Computer Science"));
}

void Library::bookHeader() const {
    line('=');
    cout << left << setw(6) << "ID" << setw(33) << "TITLE" << setw(21) << "AUTHOR"
         << "STATUS\n";
    line('-');
}

void Library::addBook() {
    string t = readText("  Enter book title  : ");
    string a = readText("  Enter author name : ");
    books.push_back(Book(t, a));
    cout << "  Book added successfully! Book ID = " << books.back().getId() << "\n";
}

void Library::showBooks() const {
    if (books.empty()) throw LibraryException("No books in the library.");
    bookHeader();
    for (const Book& b : books) cout << b;          // overloaded << operator
    line('=');
    cout << "  Total books: " << books.size() << "\n";
}

void Library::searchBook(int id) const {
    for (const Book& b : books) {
        if (b == id) {                              // overloaded == operator
            Book found = b;                         // copy constructor is called
            bookHeader();
            cout << found;
            line('=');
            return;
        }
    }
    throw LibraryException("No book found with ID " + to_string(id) + ".");
}

void Library::searchBook(const string& word) const {
    int count = 0;
    for (const Book& b : books) {
        if (toLower(b.getTitle()).find(toLower(word)) != string::npos) {
            if (count == 0) bookHeader();
            cout << b;
            count++;
        }
    }
    if (count == 0) throw LibraryException("No title contains \"" + word + "\".");
    line('=');
    cout << "  " << count << " matching book(s) found.\n";
}

void Library::addMember() {
    cout << "  Member type ->  1. Student   2. Faculty\n";
    int type = readInt("  Choose type       : ");
    if (type != 1 && type != 2) throw LibraryException("Invalid member type.");
    string n = readText("  Enter name        : ");
    Member* m;
    if (type == 1) m = new Student(nextMemberId, n, readText("  Enter course      : "));
    else           m = new Faculty(nextMemberId, n, readText("  Enter department  : "));
    members.push_back(m);
    cout << "  " << m->role() << " registered successfully! Member ID = "
         << nextMemberId++ << "\n";
}

void Library::showMembers() const {
    if (members.empty()) throw LibraryException("No members registered.");
    line('=');
    cout << left << setw(6) << "ID" << setw(22) << "NAME" << setw(10) << "ROLE"
         << setw(18) << "COURSE / DEPT" << "BOOKS\n";
    line('-');
    for (const Member* m : members) m->display();   // virtual function call
    line('=');
}

void Library::issueBook() {
    int bid = readInt("  Enter Book ID    : ");
    int b = findIndex(books, bid);                   // template function
    if (b == -1)
        throw LibraryException("Book ID " + to_string(bid) + " does not exist.");
    if (books[b].isIssued())
        throw LibraryException("\"" + books[b].getTitle() + "\" is already issued.");

    int mid = readInt("  Enter Member ID  : ");
    int m = findIndex(members, mid);                 // same template, different type
    if (m == -1)
        throw LibraryException("Member ID " + to_string(mid) + " does not exist.");
    Member* mem = members[m];
    if (mem->getBooksIssued() >= mem->maxBooks())    // virtual function call
        throw LibraryException(mem->getName() + " has reached the limit of "
                               + to_string(mem->maxBooks()) + " books.");

    Date d = readDate("  Issue date (dd mm yyyy) : ");
    books[b].issue(mid, d);
    mem->issueOne();
    cout << "  \"" << books[b].getTitle() << "\" issued to " << mem->getName()
         << " (" << mem->role() << ").\n";
    cout << "  Please return within " << LOAN_DAYS << " days to avoid fine.\n";
}

void Library::returnBook() {
    int bid = readInt("  Enter Book ID    : ");
    int b = findIndex(books, bid);
    if (b == -1)
        throw LibraryException("Book ID " + to_string(bid) + " does not exist.");
    if (!books[b].isIssued())
        throw LibraryException("This book is not issued to anyone.");

    Date rd = readDate("  Return date (dd mm yyyy) : ");
    int days = rd - books[b].getIssueDate();          // overloaded - operator
    if (days < 0) throw LibraryException("Return date cannot be before issue date.");

    int m = findIndex(members, books[b].getIssuedTo());
    if (m == -1) throw LibraryException("Member record not found.");
    Member* mem = members[m];
    int late = (days > LOAN_DAYS) ? days - LOAN_DAYS : 0;
    double fine = late * mem->finePerDay();           // runtime polymorphism

    line();
    cout << "  Book        : " << books[b].getTitle() << "\n";
    cout << "  Member      : " << mem->getName() << " (" << mem->role() << ")\n";
    cout << "  Issued on   : " << books[b].getIssueDate() << "\n";
    cout << "  Returned on : " << rd << "\n";
    cout << "  Days kept   : " << days << "   (Late by " << late << " days)\n";
    cout << "  Fine        : Rs. " << fixed << setprecision(2) << fine
         << "  (Rs. " << mem->finePerDay() << " per late day)\n";
    line();
    books[b].markReturned();
    mem->returnOne();
    cout << "  Book returned successfully.\n";
}

void Library::report() const {
    int issued = 0, students = 0;
    for (const Book& b : books) if (b.isIssued()) issued++;
    for (const Member* m : members) if (m->role() == "Student") students++;

    line('=');
    cout << "                       LIBRARY SUMMARY REPORT\n";
    line('=');
    cout << "  Total Books     : " << books.size() << "\n";
    cout << "  Books Issued    : " << issued << "\n";
    cout << "  Books Available : " << books.size() - issued << "\n";
    cout << "  Total Members   : " << members.size() << "  (Students: " << students
         << ", Faculty: " << members.size() - students << ")\n";
    line('-');
    cout << "  Currently issued books:\n";
    if (issued == 0) cout << "  (none)\n";
    for (const Book& b : books) {
        if (!b.isIssued()) continue;
        int m = findIndex(members, b.getIssuedTo());
        string who = (m == -1) ? "Unknown" : members[m]->getName();
        cout << "  " << left << setw(6) << b.getId()
             << setw(32) << b.getTitle().substr(0, 31)
             << setw(18) << who << b.getIssueDate() << "\n";
    }
    line('=');
}

// ---------- File handling : save all records ----------
void Library::saveData() const {
    ofstream bf("books.txt"), mf("members.txt");
    if (!bf || !mf) throw LibraryException("Unable to open data files for saving.");
    for (const Book& b : books) {
        Date d = b.getIssueDate();
        bf << b.getId() << '|' << b.getTitle() << '|' << b.getAuthor() << '|'
           << b.getIssuedTo() << '|' << d.getDay() << '|' << d.getMonth() << '|'
           << d.getYear() << "\n";
    }
    for (const Member* m : members)
        mf << (m->role() == "Student" ? "S" : "F") << '|' << m->getId() << '|'
           << m->getName() << '|' << m->detail() << '|' << m->getBooksIssued() << "\n";
    cout << "  " << books.size() << " books and " << members.size()
         << " members saved to books.txt and members.txt\n";
}

// ======================================================================
//  main() : menu driven program
// ======================================================================
int main() {
    Library lib;                         // constructor loads the data
    int choice;
    do {
        cout << "\n";
        line('=');
        cout << "         LIBRARY MANAGEMENT SYSTEM   (OOPs Project in C++)\n";
        line('=');
        cout << "    1. Add New Book                 6. Display All Members\n"
             << "    2. Display All Books            7. Issue Book\n"
             << "    3. Search Book by ID            8. Return Book\n"
             << "    4. Search Book by Title         9. Library Report\n"
             << "    5. Add New Member               0. Save & Exit\n";
        line('-');
        choice = readInt("    Enter your choice : ");
        try {
            switch (choice) {
                case 1: lib.addBook();     break;
                case 2: lib.showBooks();   break;
                case 3: lib.searchBook(readInt("  Enter Book ID : "));             break;
                case 4: lib.searchBook(readText("  Enter title keyword : "));     break;
                case 5: lib.addMember();   break;
                case 6: lib.showMembers(); break;
                case 7: lib.issueBook();   break;
                case 8: lib.returnBook();  break;
                case 9: lib.report();      break;
                case 0: lib.saveData();    break;
                default: throw LibraryException("Invalid choice! Please enter 0 to 9.");
            }
        }
        catch (const LibraryException& e) {              // our own exception
            cout << "  [ERROR] " << e.what() << "\n";
        }
        catch (const exception& e) {                     // standard exceptions
            cout << "  [ERROR] " << e.what() << "\n";
        }
    } while (choice != 0);
    return 0;                            // destructor of lib runs here
}
