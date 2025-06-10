import sys
import os
import subprocess
from PyQt5.QtWidgets import (
    QApplication,
    QMainWindow,
    QWidget,
    QVBoxLayout,
    QHBoxLayout,
    QListWidget,
    QPushButton,
    QLineEdit,
    QLabel,
    QProgressBar,
    QMessageBox,
)
from PyQt5.QtCore import Qt, QThread, pyqtSignal


class GitScannerThread(QThread):
    progress = pyqtSignal(int)
    repo_found = pyqtSignal(str)
    scan_complete = pyqtSignal()

    def run(self):
        home_dir = os.path.expanduser("~")
        print(f"Scanning directory: {home_dir}")  # Debug
        # Count total accessible directories
        total_dirs = 0
        for root, dirs, _ in os.walk(home_dir):
            if os.access(root, os.R_OK):
                total_dirs += len(dirs)
        # Scan for repositories
        scanned = 0
        for root, dirs, _ in os.walk(home_dir):
            if not os.access(root, os.R_OK):
                print(f"Skipping inaccessible directory: {root}")  # Debug
                continue
            if ".git" in dirs:
                print(f"Found repo: {root}")  # Debug
                self.repo_found.emit(root)
            scanned += len(dirs)
            self.progress.emit(
                int((scanned / total_dirs) * 100) if total_dirs > 0 else 100
            )
        self.scan_complete.emit()


class GitManager(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Git Repository Manager")
        self.setGeometry(100, 100, 800, 600)
        self.repos = []
        self.init_ui()

    def init_ui(self):
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        layout = QVBoxLayout(central_widget)

        # Progress bar
        self.progress_bar = QProgressBar()
        self.progress_bar.setValue(0)
        layout.addWidget(QLabel("Scanning for Git repositories..."))
        layout.addWidget(self.progress_bar)

        # Repository list
        self.repo_list = QListWidget()
        self.repo_list.itemClicked.connect(self.select_repo)
        layout.addWidget(QLabel("Found Repositories:"))
        layout.addWidget(self.repo_list)

        # Git operations
        op_layout = QHBoxLayout()
        self.commit_msg = QLineEdit()
        self.commit_msg.setPlaceholderText("Enter commit message")
        op_layout.addWidget(self.commit_msg)

        self.add_commit_btn = QPushButton("Add & Commit")
        self.add_commit_btn.clicked.connect(self.add_commit)
        op_layout.addWidget(self.add_commit_btn)

        self.push_btn = QPushButton("Push")
        self.push_btn.clicked.connect(self.push)
        op_layout.addWidget(self.push_btn)

        self.status_btn = QPushButton("Status")
        self.status_btn.clicked.connect(self.show_status)
        op_layout.addWidget(self.status_btn)

        layout.addLayout(op_layout)

        # Start scanning
        self.scanner = GitScannerThread()
        self.scanner.progress.connect(self.progress_bar.setValue)
        self.scanner.repo_found.connect(self.add_repo)
        self.scanner.scan_complete.connect(lambda: self.progress_bar.setValue(100))
        self.scanner.start()

    def add_repo(self, repo_path):
        self.repos.append(repo_path)
        self.repo_list.addItem(repo_path)

    def select_repo(self, item):
        self.selected_repo = item.text()

    def add_commit(self):
        if not hasattr(self, "selected_repo"):
            QMessageBox.warning(self, "Error", "Please select a repository.")
            return
        msg = self.commit_msg.text()
        if not msg:
            QMessageBox.warning(self, "Error", "Please enter a commit message.")
            return
        try:
            subprocess.run(["git", "-C", self.selected_repo, "add", "."], check=True)
            subprocess.run(
                ["git", "-C", self.selected_repo, "commit", "-m", msg], check=True
            )
            QMessageBox.information(self, "Success", "Changes committed.")
        except subprocess.CalledProcessError:
            QMessageBox.critical(self, "Error", "Commit failed.")

    def push(self):
        if not hasattr(self, "selected_repo"):
            QMessageBox.warning(self, "Error", "Please select a repository.")
            return
        try:
            subprocess.run(
                ["git", "-C", self.selected_repo, "push", "origin", "main"], check=True
            )
            QMessageBox.information(self, "Success", "Pushed to remote.")
        except subprocess.CalledProcessError:
            QMessageBox.critical(self, "Error", "Push failed.")

    def show_status(self):
        if not hasattr(self, "selected_repo"):
            QMessageBox.warning(self, "Error", "Please select a repository.")
            return
        result = subprocess.run(
            ["git", "-C", self.selected_repo, "status"], capture_output=True, text=True
        )
        QMessageBox.information(self, "Git Status", result.stdout)


if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = GitManager()
    window.show()
    sys.exit(app.exec_())
