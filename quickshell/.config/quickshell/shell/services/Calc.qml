pragma Singleton

import QtQuick
import Quickshell

// 式の評価器 (再帰下降パーサ)。eval は使わない。
//   evaluate("2*(3+4)") → { ok: true, isExpr: true, value: 14, text: "14" }
//   isExpr: 演算子・括弧・関数を含む「式」か (単なる数字や定数だけのときは false)
// 対応: + - * / % (剰余) ^ (べき乗, ** も可)、括弧、単項 +/-、定数 pi e tau、
//       関数 sqrt cbrt abs sin cos tan asin acos atan ln log log2 exp floor ceil round min max pow
// 全角の数字・記号 (日本語入力) は NFKC で半角にそろえる。× ÷ − も受け付ける。
Singleton {
    id: root

    readonly property int maxLength: 200
    readonly property int maxDepth: 40

    readonly property var constants: ({ pi: Math.PI, e: Math.E, tau: 2 * Math.PI })
    readonly property var functions: ({
        sqrt: Math.sqrt, cbrt: Math.cbrt, abs: Math.abs,
        sin: Math.sin, cos: Math.cos, tan: Math.tan,
        asin: Math.asin, acos: Math.acos, atan: Math.atan,
        ln: Math.log, log: Math.log10, log2: Math.log2, exp: Math.exp,
        floor: Math.floor, ceil: Math.ceil, round: Math.round,
        min: Math.min, max: Math.max, pow: Math.pow
    })

    function formatNumber(v) {
        if (Number.isInteger(v) && Math.abs(v) < 1e15)
            return String(v);
        return String(parseFloat(v.toPrecision(12)));
    }

    function _normalize(src) {
        return src.normalize("NFKC")
            .replace(/×/g, "*").replace(/÷/g, "/").replace(/[−ー]/g, "-")
            .replace(/\*\*/g, "^").replace(/，/g, ",");
    }

    function _tokenize(s) {
        const tokens = [];
        let i = 0;
        while (i < s.length) {
            const c = s[i];
            if (/\s/.test(c)) { i++; continue; }
            let m = /^(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?/.exec(s.slice(i));
            if (m) { tokens.push({ t: "num", v: parseFloat(m[0]) }); i += m[0].length; continue; }
            m = /^[A-Za-z_][A-Za-z0-9_]*/.exec(s.slice(i));
            if (m) { tokens.push({ t: "id", v: m[0].toLowerCase() }); i += m[0].length; continue; }
            if ("+-*/%^(),".indexOf(c) >= 0) { tokens.push({ t: c }); i++; continue; }
            return null;    // 使えない文字
        }
        return tokens;
    }

    // 戻り値: { ok, isExpr, value, text, error }
    function evaluate(src) {
        const fail = (msg) => ({ ok: false, isExpr: false, value: NaN, text: "", error: msg });
        if (typeof src !== "string" || src.trim() === "" || src.length > maxLength)
            return fail("empty");

        const tokens = _tokenize(_normalize(src));
        if (tokens === null || tokens.length === 0)
            return fail("syntax");

        let pos = 0;
        let depth = 0;
        let sawOp = false;
        const peek = () => tokens[pos] ? tokens[pos].t : null;
        const take = () => tokens[pos++];

        // 構文エラーは例外で巻き戻す
        const err = (m) => { throw new Error(m); };

        function expr() {
            let v = term();
            while (peek() === "+" || peek() === "-") {
                sawOp = true;
                const op = take().t;
                const r = term();
                v = op === "+" ? v + r : v - r;
            }
            return v;
        }
        function term() {
            let v = unary();
            while (peek() === "*" || peek() === "/" || peek() === "%") {
                sawOp = true;
                const op = take().t;
                const r = unary();
                v = op === "*" ? v * r : op === "/" ? v / r : v % r;
            }
            return v;
        }
        function unary() {
            if (peek() === "-") { sawOp = true; take(); return -unary(); }
            if (peek() === "+") { sawOp = true; take(); return unary(); }
            return power();
        }
        function power() {
            const base = primary();
            if (peek() === "^") {
                sawOp = true;
                take();
                return Math.pow(base, unary());    // 右結合
            }
            return base;
        }
        function primary() {
            const tk = take();
            if (!tk) err("eof");
            if (tk.t === "num") return tk.v;
            if (tk.t === "(") {
                if (++depth > root.maxDepth) err("depth");
                const v = expr();
                if (take() === undefined || tokens[pos - 1].t !== ")") err("paren");
                depth--;
                sawOp = true;
                return v;
            }
            if (tk.t === "id") {
                if (peek() === "(") {
                    const fn = root.functions[tk.v];
                    if (!fn) err("func");
                    take();
                    if (++depth > root.maxDepth) err("depth");
                    const args = [];
                    if (peek() !== ")") {
                        args.push(expr());
                        while (peek() === ",") { take(); args.push(expr()); }
                    }
                    if (take() === undefined || tokens[pos - 1].t !== ")") err("paren");
                    depth--;
                    sawOp = true;
                    return fn.apply(null, args);
                }
                if (root.constants[tk.v] !== undefined) return root.constants[tk.v];
                err("ident");
            }
            err("unexpected");
        }

        try {
            const v = expr();
            if (pos !== tokens.length)
                return fail("trailing");
            if (!isFinite(v))
                return { ok: false, isExpr: sawOp, value: v, text: "", error: "math" };
            return { ok: true, isExpr: sawOp, value: v, text: formatNumber(v), error: "" };
        } catch (e) {
            return fail(String(e.message));
        }
    }
}
