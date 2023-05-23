;;; org-active-statistics.el --- Make org todos with statistics react.

;; Copyright (C) 2023 Andrea

;; Author: Andrea <andrea-dev@hotmail.com>
;; Version: 0.0.0
;; Package-Version: 20230405.000
;; Keywords: org-mode

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Org active statistics is a simple add-on for org mode. When an org
;; heading has a TODO keyword and statistics (i.e., [0/1] or [10%]),
;; it will be affected by the completition of the sub-headings and
;; check-boxes it contains.
;;
;; See documentation on https://github.com/ag91/org-active-statistics.el

;;; Code:

(defgroup org-active-statistics.el nil
  "Options specific to Org active statistics."
  :tag "Org active statistics"
  :group 'org-active-statistics)


(defun oas/org-statistics-cookie-complete-p ()
  "Return NIL if the cookie at point is not completed."
  (if (progn
        (beginning-of-line)
        ;; get to the stats cookie
        (oas/search-in-region "\\(\\(\\[[0-9]*%\\]\\)\\|\\(\\[[0-9]*/[0-9]*\\]\\)\\)" (point-at-bol) (point-at-eol) 're-search-forward t)
        (search-backward "[" nil t))
      (progn
        (goto-char (- (point) 1))
        (or
         (save-excursion ;; case [100%]
           (oas/search-in-region ;; TODO use search forward
            "100%"
            (point)
            (save-excursion (search-forward "]" (point-at-eol) t))
            nil
            t))
         (save-excursion ;; case [x/x]
           (oas/search-in-region
            "/"
            (point)
            (save-excursion (search-forward "]" (point-at-eol) t))
            nil
            t)
           (string= (string (char-before (- (point) 1))) (string (char-after)))
           )))))

(defun oas/search-in-region (string bgn end &optional search-fn noerror count)
  "TODO" ;; TODO make interactive?
  (goto-char bgn)
  (funcall (or search-fn 'search-forward) string end noerror count))

(defun oas/org-heading-complete-p ()
  "Return NIL for a  heading containing todo headings, and the position of the last done heading otherwise."
  (save-excursion
    (let ((end (save-excursion (org-end-of-subtree))))
      (end-of-line)
      (not (search-forward "** TODO" end t)))))

(defun oas/valid-heading-p (org-heading-components)
  "A valid ORG-HEADING-COMPONENTS for a heading must have a todo and some text in the headline."
  (let ((todo-state (third org-heading-components))
        (headline (fifth org-heading-components)))
    (and todo-state headline)))

(defun oas/update-todo-if-all-subheadings-done (&args _)
  "Update todo heading to done if statistics cookie is complete and there are no todo heading pending."
  (save-excursion
    (org-back-to-heading)
    (when (oas/valid-heading-p (org-heading-components))
      (let ((todo (if (and
                       (oas/org-heading-complete-p)
                       (oas/org-statistics-cookie-complete-p))
                      "DONE"
                    "TODO")))
        (org-todo todo)))))

(defun oas/all-checkbox-done-p ()
  "Return NIL if any checkbox in the current heading is not completed (i.e.,[X])."
  (--every (not (-contains-p it "[ ]")) (org-element-property :structure (org-element-at-point))))

(defun oas/update-todo-if-all-checkboxes-done ()
  "Switch entry to DONE when all subentries are done, to TODO otherwise. Given the cookie [x/y] N-DONE is x and N-NOT-DONE is (y - x)."
  (let (org-log-done org-log-states)   ; turn off logging
    (when (oas/valid-heading-p (org-heading-components))
      (org-todo (if (oas/all-checkbox-done-p) "DONE" "TODO")))))


(defun oas/org-active-statistics-turn-off ()
  (remove-hook 'org-after-todo-statistics-hook 'oas/update-todo-if-all-subheadings-done)
  (remove-hook 'org-checkbox-statistics-hook 'oas/update-todo-if-all-checkboxes-done))

(defun oas/org-active-statistics-turn-on ()
  (add-hook 'org-after-todo-statistics-hook 'oas/update-todo-if-all-subheadings-done)
  (add-hook 'org-checkbox-statistics-hook 'oas/update-todo-if-all-checkboxes-done))

;;;###autoload

(define-minor-mode org-active-statistics
  "Toggle active statistics.
When a cookie is completed and all subtasks and checkbox are marked complete,
the task switch to  DONE."
  :group 'org-active-statistics
  (let ((are-hooks-set (or
                        (member 'oas/update-todo-if-all-subheadings-done org-after-todo-statistics-hook)
                        (member 'oas/update-todo-if-all-checkboxes-done org-checkbox-statistics-hook))))
    (if are-hooks-set
        (oas/org-active-statistics-turn-off)
      (oas/org-active-statistics-turn-on))))

(provide 'org-active-statistics.el)
;;; org-active-statistics.el ends here

;; Local Variables:
;; time-stamp-pattern: "10/Version:\\\\?[ \t]+1.%02y%02m%02d\\\\?\n"
;; End:
