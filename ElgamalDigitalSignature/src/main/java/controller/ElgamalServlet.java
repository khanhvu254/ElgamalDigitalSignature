package controller;

import model.ElgamalModel;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.math.BigInteger;

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
        BigInteger p, alpha, x, y;

        if ("random".equals(mode)) {
            // Tạo khóa ngẫu nhiên 512 bit
            BigInteger[] keys = model.generateKeys(512);
            p = keys[0]; alpha = keys[1]; x = keys[2]; y = keys[3];
        } else {
            // Tạo khóa từ đầu vào người dùng
            p = new BigInteger(req.getParameter("p"));
            alpha = new BigInteger(req.getParameter("alpha"));
            x = new BigInteger(req.getParameter("x"));
            y = alpha.modPow(x, p);
        }

        session.setAttribute("key_p", p);
        session.setAttribute("key_alpha", alpha);
        session.setAttribute("key_x", x);
        session.setAttribute("key_y", y);
        session.setAttribute("msg_gen", "Đã tạo khóa thành công!");
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
    }

    private void handleVerify(HttpServletRequest req, HttpSession session) {
        BigInteger p = (BigInteger) session.getAttribute("key_p");
        BigInteger alpha = (BigInteger) session.getAttribute("key_alpha");
        BigInteger y = (BigInteger) session.getAttribute("key_y");

        if (p == null) {
            req.setAttribute("error", "Không tìm thấy Public Key trong phiên làm việc.");
            return;
        }
        
        // Đặt lại các thuộc tính chữ ký đã ký trước đó vào request để BƯỚC 2 không bị mất
        req.setAttribute("sign_r", session.getAttribute("sign_r_session"));
        req.setAttribute("sign_s", session.getAttribute("sign_s_session"));
        req.setAttribute("last_signed_doc", session.getAttribute("last_signed_doc_session"));

        String docVerify = req.getParameter("docVerify");
        String sigR = req.getParameter("sigVerifyR");
        String sigS = ""; 

        // Validation: Kiểm tra văn bản và chữ ký có rỗng không
        if (docVerify == null || docVerify.trim().isEmpty()) {
            req.setAttribute("error", "Vui lòng nhập văn bản gốc cần xác minh!");
            req.setAttribute("verify_sig_input", sigR);
            return;
        }
        
        if (sigR == null || sigR.trim().isEmpty()) {
            req.setAttribute("error", "Vui lòng nhập chữ ký cần xác minh!");
            req.setAttribute("verify_doc_input", docVerify);
            return;
        }

        // Lưu lại dữ liệu người dùng nhập để không bị mất khi load lại trang
        req.setAttribute("verify_sig_input", sigR);
        req.setAttribute("verify_doc_input", docVerify);
        
        if(sigR.contains(",")) {
            String[] parts = sigR.split(",");
            sigR = parts[0].trim();
            sigS = parts[1].trim();
        } else {
            // Nếu người dùng chỉ nhập r mà thiếu s, ta thử gán s = r (trường hợp user nhập s vào ô r)
            sigS = req.getParameter("sigVerifyS"); 
            if(sigS == null) sigS = "";
        }
        
        boolean isValid = model.verify(docVerify, sigR, sigS, p, alpha, y);
        req.setAttribute("verify_result", isValid);
        req.setAttribute("verify_checked", true);
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
    }
    
    private void handleResetKeys(HttpSession session) {
        // Chỉ xóa các thuộc tính khóa
        session.removeAttribute("key_p");
        session.removeAttribute("key_alpha");
        session.removeAttribute("key_x");
        session.removeAttribute("key_y");
        session.removeAttribute("msg_gen");
        
        // KHÔNG xóa các thuộc tính chữ ký
    }
}