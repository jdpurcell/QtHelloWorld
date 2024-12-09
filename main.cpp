#include <QtWidgets>

class MainWindow : public QMainWindow {
public:
    MainWindow(QWidget *parent = nullptr) : QMainWindow{parent} {
        setWindowTitle("Hello World");
        setCentralWidget(new QWidget(this));
    }
};

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    MainWindow *win = new MainWindow();
    win->show();
    return app.exec();
}
