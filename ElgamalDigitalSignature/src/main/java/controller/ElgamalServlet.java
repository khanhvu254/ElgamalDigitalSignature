package controller;

import model.ElgamalModel;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

@WebServlet("/process")
public class ElgamalServlet extends HttpServlet {
    private ElgamalModel model = new ElgamalModel();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String action = req.getParameter("action");
        HttpSession session = req.getSession();

        try {
            switch (action) {
                case "generateKeys":
                    handleGenerateKeys(req, session);
                    break;
                case "sign":
                    handleSign(req, session);
                    break;
                case "verify":
                    handleVerify(req, session);
                    break;
                case "reset":
                    handleReset(session);
                    break;
                case "resetKeys":
                    handleResetKeys(session);
                    break;
            }
        } catch (Exception e) {
            req.setAttribute("error", "Lỗi xử lý: " + e.getMessage());
        }

        req.getRequestDispatcher("index.jsp").forward(req, resp);
    }

    private void handleGenerateKeys(HttpServletRequest req, HttpSession session) {

        String mode = req.getParameter("genMode");

        if ("random".equals(mode)) {
            BigInteger[] keys = model.generateKeys(512);
            session.setAttribute("key_p", keys[0]);
            session.setAttribute("key_alpha", keys[1]);
            session.setAttribute("key_x", keys[2]);
            session.setAttribute("key_y", keys[3]);
            req.setAttribute("p", keys[0]);
            req.setAttribute("alpha", keys[1]);
            req.setAttribute("x", keys[2]);
            session.setAttribute("msg_gen", "Đã tạo khóa ngẫu nhiên thành công!");
            return;
        }

        try {
            BigInteger p = new BigInteger(req.getParameter("p"));
            BigInteger alpha = new BigInteger(req.getParameter("alpha"));
            BigInteger x = new BigInteger(req.getParameter("x"));

            // KIỂM TRA ĐIỀU KIỆN
            String error = model.validateInputKeys(p, alpha, x);
            if (error != null) {
                req.setAttribute("error", "Lỗi tạo khóa: " + error);
                req.setAttribute("input_p", p);
                req.setAttribute("input_alpha", alpha);
                req.setAttribute("input_x", x);
                return;
            }

            BigInteger y = alpha.modPow(x, p);

            session.setAttribute("key_p", p);
            session.setAttribute("key_alpha", alpha);
            session.setAttribute("key_x", x);
            session.setAttribute("key_y", y);
            session.setAttribute("msg_gen", "Đã tạo khóa thành công!");

        } catch (NumberFormatException e) {
            req.setAttribute("error", "Vui lòng nhập đúng định dạng số nguyên!");
        }
    }


    private void handleSign(HttpServletRequest req, HttpSession session) throws Exception {
        BigInteger p = (BigInteger) session.getAttribute("key_p");
        BigInteger alpha = (BigInteger) session.getAttribute("key_alpha");
        BigInteger x = (BigInteger) session.getAttribute("key_x");

        if (p == null || x == null) {
            req.setAttribute("error", "Chưa có khóa! Vui lòng tạo khóa ở Bước 1.");
            return;
        }

        String docContent = req.getParameter("docContent");
        
        // Validation: Kiểm tra văn bản có rỗng không
        if (docContent == null || docContent.trim().isEmpty()) {
            req.setAttribute("error", "Vui lòng nhập văn bản cần ký!");
            return;
        }

        String[] signature = model.sign(docContent, p, alpha, x);

        // Đặt chữ ký vào session (để giữ lại sau verify) và request
        session.setAttribute("sign_r_session", signature[0]);
        session.setAttribute("sign_s_session", signature[1]);
        session.setAttribute("last_signed_doc_session", docContent);

        req.setAttribute("sign_r", signature[0]);
        req.setAttribute("sign_s", signature[1]);
        req.setAttribute("last_signed_doc", docContent);
        
        addToHistory(session, "sign", "Ký văn bản (độ dài: " + docContent.length() + " ký tự)", null);
    }

    private void handleVerify(HttpServletRequest req, HttpSession session) {
        BigInteger p = (BigInteger) session.getAttribute("key_p");
        BigInteger alpha = (BigInteger) session.getAttribute("key_alpha");
        BigInteger y = (BigInteger) session.getAttribute("key_y");

        if (p == null) {
            req.setAttribute("error", "Không tìm thấy Public Key trong phiên làm việc.");
            return;
        }

        // Giữ dữ liệu BƯỚC 2
        req.setAttribute("sign_r", session.getAttribute("sign_r_session"));
        req.setAttribute("sign_s", session.getAttribute("sign_s_session"));
        req.setAttribute("last_signed_doc", session.getAttribute("last_signed_doc_session"));

        String docVerify = req.getParameter("docVerify");
        String sigInput = req.getParameter("sigVerifyR");

        if (docVerify == null || docVerify.trim().isEmpty()) {
            req.setAttribute("error", "Vui lòng nhập văn bản gốc cần xác minh!");
            req.setAttribute("verify_sig_input", sigInput);
            return;
        }

        if (sigInput == null || sigInput.trim().isEmpty()) {
            req.setAttribute("error", "Vui lòng nhập chữ ký cần xác minh!");
            req.setAttribute("verify_doc_input", docVerify);
            return;
        }

        req.setAttribute("verify_sig_input", sigInput);
        req.setAttribute("verify_doc_input", docVerify);

        // Tách r,s
        String sigR = "", sigS = "";
        if (sigInput.contains(",")) {
            String[] parts = sigInput.split(",");
            sigR = parts[0].trim();
            sigS = parts[1].trim();
        }

        boolean isValid = model.verify(docVerify, sigR, sigS, p, alpha, y);

        // PHÂN BIỆT NGUYÊN NHÂN
        String origR = (String) session.getAttribute("sign_r_session");
        String origS = (String) session.getAttribute("sign_s_session");

        String verifyStatus;
        boolean sigChanged =
                !sigR.equals(origR) || !sigS.equals(origS);

        boolean docChanged =
                !docVerify.equals(session.getAttribute("last_signed_doc_session"));

        if (isValid) {
            verifyStatus = "OK";
        } else if (sigChanged && docChanged) {
            verifyStatus = "BOTH_MODIFIED";
        } else if (sigChanged) {
            verifyStatus = "SIG_MODIFIED";
        } else {
            verifyStatus = "DOC_MODIFIED";
        }

        req.setAttribute("verify_status", verifyStatus);
        req.setAttribute("verify_checked", true);
        
        String result = isValid ? "Thành công (TRÙNG KHỚP)" : "Thất bại (" + verifyStatus + ")";
        addToHistory(session, "verify", "Xác minh văn bản (kết quả: " + result + ")", null);
    }

    
    private void handleReset(HttpSession session) {
        // Xóa các thuộc tính khóa
        session.removeAttribute("key_p");
        session.removeAttribute("key_alpha");
        session.removeAttribute("key_x");
        session.removeAttribute("key_y");
        session.removeAttribute("msg_gen");
        
        // Xóa các thuộc tính chữ ký 
        session.removeAttribute("sign_r_session");
        session.removeAttribute("sign_s_session");
        session.removeAttribute("last_signed_doc_session");
        
        // Xóa lịch sử hoạt động
        session.removeAttribute("history");
    }
    
    private void handleResetKeys(HttpSession session) {
        // Chỉ xóa các thuộc tính khóa
        session.removeAttribute("key_p");
        session.removeAttribute("key_alpha");
        session.removeAttribute("key_x");
        session.removeAttribute("key_y");
        session.removeAttribute("msg_gen");
        
        addToHistory(session, "resetKeys", "Reset khóa", null);
    }
    
    private void addToHistory(HttpSession session, String action, String data, String kValue) {
        ArrayList<Map<String, String>> history = (ArrayList<Map<String, String>>) session.getAttribute("history");
        if (history == null) {
            history = new ArrayList<>();
        }
        
        Map<String, String> entry = new HashMap<>();
        entry.put("action", action);
        entry.put("data", data);
        if (kValue != null) {
            entry.put("k", kValue);
        }
        entry.put("timestamp", new java.util.Date().toString());
        
        history.add(entry);
        session.setAttribute("history", history);
    }

}