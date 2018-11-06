/*
  pygame - Python Game Library
  Copyright (C) 2000-2001  Pete Shinners

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Library General Public
  License as published by the Free Software Foundation; either
  version 2 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Library General Public License for more details.

  You should have received a copy of the GNU Library General Public
  License along with this library; if not, write to the Free
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

  Pete Shinners
  pete@shinners.org
*/

#include "pygame.h"
#include "pgcompat.h"

#define DEFAULT_WINDOW_TITLE "pygame"
#define DEFAULT_WINDOW_WIDTH 640
#define DEFAULT_WINDOW_HEIGHT 480

#define DOC_PYGAMEWINDOW NULL

typedef struct {
    PyObject_HEAD
    SDL_Window *window;
} pg_window_t;

static PyObject*
pg_window_new(PyTypeObject *subtype, PyObject *args, PyObject *kwds)
{
    return subtype->tp_alloc(subtype, 0);
}

static void
pg_window_dealloc(PyObject *self)
{
    if (((pg_window_t*)self)->window)
        SDL_DestroyWindow(((pg_window_t*)self)->window);
    Py_TYPE(self)->tp_free(self);
}

static int
pg_window_init(PyObject *self, PyObject *args, PyObject *kwargs)
{
    const char *keywords[] = {
        "title",
        "position",
        "size",
        "flags",
        NULL
    };
    int x = SDL_WINDOWPOS_UNDEFINED;
    int y = SDL_WINDOWPOS_UNDEFINED;
    unsigned int w = DEFAULT_WINDOW_WIDTH;
    unsigned int h = DEFAULT_WINDOW_HEIGHT;
    int flags = 0;
    const char *title = DEFAULT_WINDOW_TITLE;
    SDL_Window *win;

    VIDEO_INIT_CHECK();

    if (!PyArg_ParseTupleAndKeywords(args, kwargs, "|s(ii)(II)I", keywords,
                                     &title, &x, &y, &w, &y, &flags))
        return -1;

    win = SDL_CreateWindow(title, x, y, w, h, flags);
    if (!win) {
        RAISE(pgExc_SDLError, SDL_GetError());
        return -1;
    }
    ((pg_window_t*)self)->window = win;

    return 0;
}

static PyTypeObject pgWindow_type = {
    TYPE_HEAD(NULL, 0) "Window",  /*name*/
    sizeof(pg_window_t),          /*basic size*/
    0,                            /*itemsize*/
    pg_window_dealloc,            /*dealloc*/
    0,                            /*print*/
    NULL,                         /*getattr*/
    NULL,                         /*setattr*/
    NULL,                         /*compare*/
    NULL,                         /*repr*/
    NULL,                         /*as_number*/
    NULL,                         /*as_sequence*/
    NULL,                         /*as_mapping*/
    NULL,                         /*hash*/
    NULL,                         /*call*/
    NULL,                         /*str*/
    0,
    0,
    0,
    Py_TPFLAGS_DEFAULT,                       /* tp_flags */
    DOC_PYGAMEWINDOW,                         /* Documentation string */
    0,                                        /* tp_traverse */
    0,                                        /* tp_clear */
    0,                                        /* tp_richcompare */
    0,                                        /* tp_weaklistoffset */
    0,                                        /* tp_iter */
    0,                                        /* tp_iternext */
    0,                                        /* tp_methods */
    0,                                        /* tp_members */
    0,                                        /* tp_getset */
    0,                                        /* tp_base */
    0,                                        /* tp_dict */
    0,                                        /* tp_descr_get */
    0,                                        /* tp_descr_set */
    0,                                        /* tp_dictoffset */
    pg_window_init,                           /* tp_init */
    0,                                        /* tp_alloc */
    pg_window_new,                            /* tp_new */
};

MODINIT_DEFINE(window)
{
    PyObject *module, *dict;

#if PY3
    static struct PyModuleDef _module = {PyModuleDef_HEAD_INIT,
                                         "window",
                                         DOC_PYGAMEWINDOW,
                                         -1,
                                         NULL,
                                         NULL,
                                         NULL,
                                         NULL,
                                         NULL};
#endif

    /* imported needed apis; Do this first so if there is an error
       the module is not loaded.
    */
    import_pygame_base();
    if (PyErr_Occurred()) {
        MODINIT_ERROR;
    }

    /* type preparation */
    if (PyType_Ready(&pgWindow_type) < 0) {
        MODINIT_ERROR;
    }

    /* create the module */
#if PY3
    module = PyModule_Create(&_module);
#else
    module = Py_InitModule3(MODPREFIX "window", NULL, DOC_PYGAMEWINDOW);
#endif
    if (module == NULL) {
        MODINIT_ERROR;
    }
    dict = PyModule_GetDict(module);

    if (PyDict_SetItemString(dict, "Window", &pgWindow_type)) {
        DECREF_MOD(module);
        MODINIT_ERROR;
    }

    MODINIT_RETURN(module);
}
