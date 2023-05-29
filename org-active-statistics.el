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


(defun oas/valid-heading-p (org-heading-components)
  "A valid ORG-HEADING-COMPONENTS for a heading must have a todo and some text in the headline."
  (let ((todo-state (third org-heading-components))
        (headline (fifth org-heading-components)))
    (and todo-state headline)))

(defun oas/all-checkbox-done-p ()
  "Return NIL if any checkbox in the current heading is not completed (i.e.,[X])."
  (save-excursion
    (org-up-heading-safe)
    (org-narrow-to-subtree)
    (let ((result (not (search-forward " [ ]" nil t))))
      (widen)
      result)))

(defun oas/all-subheading-done-p ()
  "Return NIL if any there is any \"** TODO\" in the current heading."
  (save-excursion
    (org-up-heading-safe)
    (end-of-line)
    (let ((end (save-excursion (org-end-of-subtree))))
      (if (search-forward "** DONE" end t)
          (not (search-forward "** TODO" end t))
        t))))

(defun oas/update-heading-by-completion (&optional _ _)
  "Update heading by completion."
  (save-excursion
    (org-back-to-heading)
    (when (oas/valid-heading-p (org-heading-components))
      (let (org-log-done
            org-log-states
            (todo (if (and
                       (oas/all-checkbox-done-p)
                       (oas/all-subheading-done-p))
                      "DONE"
                    "TODO")))
        (org-todo todo)))))

(defun oas/org-active-statistics-turn-off ()
  (remove-hook 'org-after-todo-statistics-hook 'oas/update-heading-by-completion)
  (remove-hook 'org-checkbox-statistics-hook 'oas/update-heading-by-completion))

(defun oas/org-active-statistics-turn-on ()
  (add-hook 'org-after-todo-statistics-hook 'oas/update-heading-by-completion)
  (add-hook 'org-checkbox-statistics-hook 'oas/update-heading-by-completion))

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

(provide 'org-active-statistics)
;;; org-active-statistics.el ends here

;; Local Variables:
;; time-stamp-pattern: "10/Version:\\\\?[ \t]+1.%02y%02m%02d\\\\?\n"
;; End:
