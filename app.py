import os
import re
from flask import Flask, jsonify, render_template, send_from_directory
from flask_login import LoginManager
from flask_cors import CORS
from flask_session import Session
from config import config_map
from database import init_db, db
from routes import register_blueprints
from routes.web import web_bp
from services import bcrypt

def create_app(config_name=None):
    if config_name is None:
        config_name = os.getenv("FLASK_ENV", "development")
    app = Flask(__name__, template_folder="templates", static_folder="static")
    app.config.from_object(config_map.get(config_name, config_map["default"]))

    init_db(app)
    bcrypt.init_app(app)
    Session(app)
    CORS(app, supports_credentials=True)

    login_manager = LoginManager(app)
    login_manager.login_view = "web.login"
    login_manager.login_message = "Please log in to continue."
    login_manager.login_message_category = "warning"

    @login_manager.user_loader
    def load_user(user_id):
        from models import User
        return User.query.get(int(user_id))

    @login_manager.unauthorized_handler
    def unauthorised():
        from flask import request, redirect, url_for
        if request.path.startswith("/api/"):
            return jsonify({"success": False, "message": "Authentication required."}), 401
        return redirect(url_for("web.login"))

    app.register_blueprint(web_bp)
    register_blueprints(app)

    @app.route("/assets/<path:filename>")
    def serve_assets(filename):
        assets_dir = os.path.join(app.root_path, "assets")
        requested = os.path.join(assets_dir, filename)
        if os.path.exists(requested):
            return send_from_directory(assets_dir, filename)

        base = os.path.basename(filename)
        name, ext = os.path.splitext(base)
        norm = ''.join(ch for ch in name.lower() if ch.isalnum())

        best_match = None
        best_score = 0
        for root, _, files in os.walk(assets_dir):
            for f in files:
                fname, fext = os.path.splitext(f)
                fnorm = ''.join(ch for ch in fname.lower() if ch.isalnum())
                score = 0
                if fnorm == norm:
                    score = 100
                elif norm in fnorm or fnorm in norm:
                    score = 80
                elif any(token in fnorm for token in re.split(r"[^a-z0-9]", norm) if token):
                    score = 50
                if score > 0:
                    if fext.lower() == ext.lower():
                        score += 10
                    if score > best_score:
                        best_score = score
                        best_match = os.path.relpath(os.path.join(root, f), assets_dir)
                        if score >= 110:
                            break
            if best_score >= 110:
                break

        if best_match:
            return send_from_directory(assets_dir, best_match)

        # Fallback to any same basename ignoring extension
        for root, _, files in os.walk(assets_dir):
            for f in files:
                fname, _ = os.path.splitext(f)
                if fname.lower() == name.lower():
                    rel = os.path.relpath(os.path.join(root, f), assets_dir)
                    return send_from_directory(assets_dir, rel)

        return send_from_directory(assets_dir, filename)

    @app.errorhandler(404)
    def not_found(e):
        from flask import request
        if request.path.startswith("/api/"):
            return jsonify({"success": False, "message": "Not found."}), 404
        return render_template("404.html"), 404

    @app.errorhandler(500)
    def server_error(e):
        db.session.rollback()
        from flask import request
        if request.path.startswith("/api/"):
            return jsonify({"success": False, "message": "Server error."}), 500
        return render_template("404.html"), 500

    @app.route("/api/health")
    def health():
        return jsonify({"success": True, "message": "OneReserve API running.", "version": "1.0.0"})

    return app

app = create_app()

if __name__ == "__main__":
    with app.app_context():
        import models  # noqa
    app.run(host=os.getenv("HOST","0.0.0.0"), port=int(os.getenv("PORT",5000)), debug=app.config["DEBUG"])
